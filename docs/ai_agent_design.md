# AI Analyst（自然言語分析エージェント）実装設計

## 1. 採用構成

AI Analystは、ClaudeによるSQL生成と、ブラウザ内DuckDB-WASMによるSQL実行を分離する。

- サーバー: Anthropic APIを1回呼び出すステートレス・プロキシ。APIキー、プロンプト、SQL安全性検証、rate limitを担当する。
- ブラウザ: 公開Parquetを取得し、DuckDB-WASMで7つのviewを作成する。Anthropic tool useの会話ループとSQL実行を担当する。
- データ: `web/public/marts/*.parquet`の公開7 mart。すべて合成データで、顧客粒度の内部RFM martは含めない。

この分離は、DuckDB-WASMのWebAssembly資産をNext.jsのNodeサーバーバンドルへ含めず、本来のブラウザ実行環境で利用するために採用する。

## 2. 処理フロー

1. ユーザーが日本語で質問する。
2. Client ComponentがAnthropic形式の`messages`を作り、`POST /api/analyst`へ渡す。
3. API routeが入力、質問長、rate limitを検査し、Claude Messages APIを1回呼ぶ。
4. Claudeが`run_sql`を返した場合、API routeがSQLを検証し、生のassistant contentと検証結果を返す。
5. 検証済みSQLならブラウザ内DuckDB-WASMで実行する。無効SQLまたは実行エラーならエラー内容を作る。
6. Client Componentが結果を`tool_result`として会話履歴へ加え、API routeを再度呼ぶ。
7. 最終回答を受け取ったら、自然言語回答、使用SQL、結果の先頭50行を表示する。最大5反復で停止する。

サーバーは会話状態およびクエリ結果を保持せず、各リクエストの`messages`だけをClaudeへ中継する。

## 3. ブラウザ側DuckDB

- `analyst-chat.tsx`をClient Componentとする。
- `@duckdb/duckdb-wasm`はdynamic importし、`getJsDelivrBundles()`、`selectBundle()`、Web Workerを使う。
- WASMとWorkerはjsDelivr CDNから取得する。利用者のブラウザからjsDelivrへ接続できることが実行条件となる。
- `/marts/mart_*.parquet`をfetchし、`registerFileBuffer`で登録する。
- 各ファイルを`parquet_scan()`する同名viewを作る。
- 初期化Promiseをモジュールスコープでメモ化し、同一ページセッション内で再利用する。初期化失敗時だけ破棄して再試行可能にする。
- 実行SQLをサブクエリ化し、1,001行で打ち切る。tool resultと画面には先頭50行だけを含める。
- BigInt、日付、NULLをJSON安全な形式へ変換する。

## 4. API route

`/api/analyst`はNode runtimeで動かすが、DuckDB関連moduleをimportしない。

- 入力: `{ messages }`
- Claude呼び出し: `tools=[run_sql]`、`max_tokens=1500`、既定モデル`claude-sonnet-5`
- モデルは`AGENT_MODEL`で上書き可能
- system promptはschema、指標定義、DuckDB方言、参照可能mart、tool利用制約を含み、ephemeral prompt cacheを指定する
- 出力: `assistantContent`、`stopReason`、`toolUses[]`（SQL、valid、reason）、model
- `ANTHROPIC_API_KEY`未設定時は503と利用者向けメッセージを返す
- API呼び出し失敗時は内部詳細を公開せず502を返す

## 5. ガードレール

SQLはサーバー側で必ず検証する。

- `SELECT`または`WITH`で始まる単一文だけを許可する
- INSERT、UPDATE、DELETE、CREATE、DROP、ALTER、ATTACH、COPY、PRAGMA、INSTALL、LOADなどを拒否する
- 外部ファイル関数、system table、許可外tableを拒否する
- 参照可能tableを公開7 martとSQL内CTEに限定する
- SQL長を20,000文字以内とする
- 質問を2,000文字以内、会話を12 message以内、requestを概ね160KB以内とする
- IP単位のインメモリrate limitを適用する

ブラウザはサーバーが`valid: true`を返したSQLだけを実行する。Client側の行数制限は、結果転送量と画面負荷を抑えるための追加防御である。

## 6. 運用上の注意

- IP rate limitはserverless instance単位のbest effortであり、厳密な全体制限ではない。公開後の濫用状況に応じて永続ストア型へ移行を検討する。
- jsDelivr障害、CDN制限、CSP設定、ブラウザのWebAssembly/Worker対応状況によりDuckDB初期化が失敗し得る。エラーはUIで再試行可能な形で表示する。
- APIキーはサーバー環境変数だけに置き、クライアントへ渡さない。
- SQLは安全性検証後も生成結果と解釈を利用者が確認できるよう画面に表示する。
- 公開データは合成データであり、実在事業の実績ではないことを明記する。
