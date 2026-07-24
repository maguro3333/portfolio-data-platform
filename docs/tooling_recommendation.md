# ECデータ基盤ポートフォリオ向け MCP／Claude Code skill 推奨案

## 1. 本書の位置づけ

本書は、Claude Codeがトークン消費と操作ミスを抑えながら、GCP版・AWS版のECデータ基盤を並行構築するためのツール選定案である。最終判断前のレビュー資料として、導入を前提にせず、CLIで十分な領域とMCPに価値がある領域を分けている。

調査基準日は **2026-07-23**。候補は、公式ベンダー／公式プロジェクトの公開物として識別できるものに限定した。ただし、この調査環境では公式サイトへのライブ接続がDNS制限で失敗したため、リリース番号、Claude Codeとの最新の接続手順、Preview／GAの状態は導入時に各公式リンクで再確認する必要がある。不確かな提供形態は「要確認」とした。

### 現環境で確認できた事実

`command -v` による読み取り確認結果：

| コマンド | 状態 |
|---|---|
| `node` | `/usr/local/bin/node` |
| `npm` | `/usr/local/bin/npm` |
| `git` | `/usr/bin/git` |
| `gcloud` / `bq` | PATH上に見つからない |
| `aws` | PATH上に見つからない |
| `terraform` | PATH上に見つからない |
| `dbt` | PATH上に見つからない |

未検出は「未インストール」とは限らず、別PATH、仮想環境、コンテナ内にある可能性は残る。インストール前に `brew list`、`pipx list`、プロジェクト設定、既存認証情報を確認することを提案する。

---

## 2. 結論

### 今すぐ導入する最小セット

MCPを増やす前に、次を最小セットとする案を推奨する。

1. **既存の `codex` MCP**
2. **既存の `fewer-permission-prompts` skill**
3. **GCP CLI（Google Cloud CLI。`gcloud` / `bq` / `gsutil`）**
4. **AWS CLI v2**
5. **Terraform CLI**
6. **dbt Core + 対象アダプター**（変換基盤にdbtを正式採用する場合）
7. **プロジェクトローカルの短いClaude Code skills**

最初から追加MCPを必須にしない理由は、このプロジェクトの主要処理が、SQL・Python・Terraform・シェルとしてGit管理できる決定的な処理だからである。CLIは出力をファイルへ保存しやすく、Claudeへ渡す情報量を制御しやすい。MCPは便利でも、ツール定義、巨大なレスポンス、毎ターンの探索がコンテキストを消費する場合がある。

### 最初に追加MCPを1つだけ選ぶ場合

**HashiCorp公式 Terraform MCP Server**を第一候補とする。ただし主用途はTerraform Registryのプロバイダー／モジュール仕様確認とし、`plan` / `apply` の実行自体はCLIを正とする案を推奨する。

### 後から追加する有力候補

- AWS構築段階：AWS Labs MCP Serversのうち、Documentation／Knowledge系
- dbtモデルが増えた段階：dbt Labs公式 dbt MCP Server
- BigQuery探索が反復的になった段階：Google公式 MCP Toolbox for Databases、またはGoogle CloudのBigQuery向け公式リモートMCP（提供状態を要確認）
- ポートフォリオサイトのUI検証段階：Microsoft公式 Playwright MCP Server
- GitHub Issues／PRをClaude Codeから運用する段階：GitHub公式 MCP Server

---

## 3. 判断原則：CLI、MCP、skillの役割分担

| 手段 | 向いている処理 | このプロジェクトでの位置づけ |
|---|---|---|
| CLI | 再現可能な作成・検証・デプロイ、ログ保存、CI実行 | 原則として実装の正本 |
| MCP | メタデータ探索、公式知識検索、複数APIの構造化操作 | 反復探索が増えた領域だけ追加 |
| Claude Code skill | 手順、命名、レビュー観点、出力形式の固定 | トークン節約に最も費用対効果が高い |
| SDK／Python | サンプル生成、複雑な検証、API処理 | Git管理できる実装として使用 |
| Web UI | OAuth初期設定、Looker Studio／Tableau Public編集 | CLI/APIで代替できない操作に限定 |

「MCPならCLIより常に省トークン」とは限らない。大きなスキーマやログをMCPが毎回返す場合、`CLI > artifact.log` と `rg` / `sed` で必要部分だけ読む方が小さくなる。MCPは認証、ページング、構造化結果、知識検索に明確な利点がある場合に追加するのがよい。

---

## 4. 工程別の外部MCP候補

評価：

- 導入価値：高／中／低
- 難易度：低／中／高
- コスト：サーバー利用料だけでなく、背後のクラウドAPI・dbt Cloud等の料金も分けて考える

## 4.1 サンプルデータ生成

### 推奨：追加MCPなし

Python、Faker、NumPy、Polars／pandas、DuckDB等で生成スクリプトと統計検証をGit管理する方が適する。

| 項目 | 評価 |
|---|---|
| 導入価値 | 外部MCPは低 |
| CLI代替 | 完全に可能 |
| 難易度 | Python環境の整備のみ |
| コスト | 無料 |

生成の再現性には乱数seed、分布パラメータ、件数、生成バージョンを設定ファイルへ分離する。Claudeに数十万行を読ませず、行数、NULL率、分位点、参照整合性、サンプル20行程度の検証レポートだけを読ませる。

### 候補外とするもの

汎用DB MCPをDuckDB／SQLiteへ接続することは可能だが、初期段階ではCLIや小さな検証SQLより優位性が少ない。MCP経由の任意SQL実行は権限面も増えるため、導入しない案を推奨する。

## 4.2 GCP／BigQuery操作

### 候補A：MCP Toolbox for Databases

- 提供元：Google公式 `googleapis/genai-toolbox`
- 公式情報：<https://github.com/googleapis/genai-toolbox>
- 位置づけ：データベース向けのオープンソースMCP Toolbox。BigQuery対応ツールセットの有無と現行設定名は導入時に公式ドキュメントで要確認

| 項目 | 評価 |
|---|---|
| 導入価値 | 中 |
| CLI代替 | `bq`、Python BigQuery client、SQLファイルで可能 |
| 難易度 | 中。バイナリ／コンテナ、ADC、ツール定義、最小権限設定 |
| コスト | Toolbox自体はOSS。BigQueryの保存・クエリ料金は別 |

**入れる価値**：Claudeがテーブル一覧、スキーマ、限定的な集計結果を繰り返し取得する段階では、構造化された操作に価値がある。

**懸念**：自由なSQL実行を許可すると、全表スキャンや変更系SQLにつながる。開発初期は読み取り専用サービスアカウント、最大処理バイト、対象datasetの限定を提案する。

### 候補B：Google Cloud公式のBigQuery向けリモートMCP

Google Cloudはサービス別のリモートMCP提供を進めているが、BigQuery版の提供地域、Preview／GA、認証方法、Claude Codeからの利用可否は変化しやすいため、**要確認**とする。

- 公式確認起点：<https://cloud.google.com/mcp>
- 導入価値：中～高になり得る
- CLI代替：可能
- 難易度：中～高
- コスト：MCP接続自体に加えてBigQuery実行料金を確認

安定版と最小権限構成が確認できるまでは、ポートフォリオの再現手順をこれに依存させない方が安全である。

### 推奨する実装手段

GCPリソースの作成・削除・デプロイは、Terraform＋`gcloud` / `bq`を正とする。MCPはメタデータ探索と読み取り診断に限定する。

## 4.3 AWS／S3・Glue・Athena・Lambda操作

### 候補：AWS Labs MCP Servers

- 提供元：AWS Labs公式 `awslabs/mcp`
- 公式情報：<https://github.com/awslabs/mcp>
- 複数のMCPサーバーを収録するため、「AWS MCP一式」ではなく必要なサーバーだけを選ぶ

#### Documentation／Knowledge系

| 項目 | 評価 |
|---|---|
| 導入価値 | 中～高 |
| CLI代替 | AWS CLIでは公式ドキュメントの意味検索を完全代替しにくい |
| 難易度 | 低～中 |
| コスト | サーバー自体はOSS候補。背後のサービス利用料は要確認 |

Athena DDL、Glue Catalog、Lambdaランタイム、IAM条件など、仕様確認が多い段階で有効。一般Web検索より公式AWS資料へ範囲を限定しやすい。

#### AWS API操作系

| 項目 | 評価 |
|---|---|
| 導入価値 | 中 |
| CLI代替 | AWS CLI／SDK／Terraformで可能 |
| 難易度 | 高。AWS認証、IAM、許可コマンド、リージョン、破壊操作の制御 |
| コスト | MCP自体とは別に、呼び出したAWSサービス料金が発生 |

構造化API操作は便利だが、Claudeが直接リソースを変更できる範囲が広くなりやすい。初期導入は推奨せず、必要になった場合もread-onlyプロファイルと専用sandboxアカウントから始める。

### 推奨する実装手段

AWS構築はTerraform＋AWS CLIを正とする。`aws athena start-query-execution` 等では、workgroupにスキャン上限、結果出力先、暗号化を設定する。MCP経由でも同じ課金防止策が必要である。

## 4.4 IaC

### 強い候補：HashiCorp Terraform MCP Server

- 提供元：HashiCorp公式
- 公式情報：<https://github.com/hashicorp/terraform-mcp-server>

| 項目 | 評価 |
|---|---|
| 導入価値 | 高（Registry調査）、中（実行） |
| CLI代替 | `terraform` CLIとRegistry Web検索で可能 |
| 難易度 | 低～中。配布形態、Claude Code設定、必要ならHCP認証 |
| コスト | OSSサーバー／Registry参照は原則無料候補。HCP Terraform利用は契約を別確認 |

**有効な用途**

- AWS／Google providerのresource・argument仕様検索
- 公式module／provider versionの確認
- 古い引数や非推奨設定の早期発見

**CLIを正とする用途**

- `terraform fmt -check`
- `terraform validate`
- `terraform plan -out=...`
- 保存済みplanの要約
- `terraform apply`／`destroy`

`apply` と `destroy` はMCPに広い自動承認を与えず、人間確認を残す。ポートフォリオでは、生成されたコードだけでなくplan、lint、セキュリティ検査が再現できることが重要である。

## 4.5 dbt的なデータ変換

### 候補：dbt Labs公式 dbt MCP Server

- 提供元：dbt Labs公式 `dbt-labs/dbt-mcp`
- 公式情報：<https://github.com/dbt-labs/dbt-mcp>

| 項目 | 評価 |
|---|---|
| 導入価値 | dbt採用後は中～高。採用前は低 |
| CLI代替 | dbt Core CLI、`manifest.json`、`catalog.json`、SQLで可能 |
| 難易度 | 中。dbt環境、adapter、接続情報。機能によってdbt Platform認証 |
| コスト | OSS部分は無料候補。dbt Platform機能はプラン確認が必要 |

モデル探索、lineage、Semantic Layer、job情報への自然言語アクセスには価値がある。一方、この規模では `dbt ls --output json`、`dbt compile`、`dbt build --select` とartifactの部分読みで十分な可能性が高い。

### 関連skill候補：dbt Labs公式 agent skills

dbt Labsが公開するエージェント向けskillsが現行でClaude Codeを正式サポートしている場合は候補になる。ただしリポジトリ名、インストール方法、dbt Core／Platformの対象範囲は導入時にdbt Labs公式資料で**要確認**とする。

外部skillをそのまま採用するより、本プロジェクトの命名規則、materialization、BigQuery／Athena差分を記したローカルskillを併用した方が、毎回の説明を短くできる。

## 4.6 BI連携

### Looker Studio

LookerとLooker Studioは別製品である。Looker向けMCPが存在しても、Looker Studioのレポート編集を自動化できるとは限らない。現時点では、Looker Studio専用MCPを中核依存にすることは提案しない。

- データ提供：BigQuery mart／公開用extract
- 検証：SQLによるKPI照合、ブラウザでの目視
- ダッシュボード設計：既存 `dataviz` skill

### Tableau Public

Tableau／Salesforce系のMCP提供は製品・契約・Preview状態の確認が必要であり、Tableau Publicのワークブック編集・公開まで対応するとは限らない。今回の無料ポートフォリオでは必須候補にしない。

- データ提供：匿名化済みHyper／CSV／Parquet抽出
- 自動化候補：Tableau Hyper API、Document API、既存CLIが要件を満たす範囲
- 公開操作：Tableau Public Desktop／Web UI

BI値の正しさは、MCPではなく、同じフィルター条件に対する期待SQLとダッシュボード値の照合表で保証する方が再現しやすい。

## 4.7 Next.jsポートフォリオサイト

### 候補：Microsoft Playwright MCP Server

- 提供元：Microsoft公式 `microsoft/playwright-mcp`
- 公式情報：<https://github.com/microsoft/playwright-mcp>

| 項目 | 評価 |
|---|---|
| 導入価値 | UIデバッグ時は中～高。実装初期は低 |
| CLI代替 | Playwright Test、ブラウザDevToolsで可能 |
| 難易度 | 低～中。Node、ブラウザ、MCP設定 |
| コスト | OSS。CIやホスティング費用は別 |

iframe表示、レスポンシブ、リンク、アクセシビリティ、コンソールエラーの対話的調査に有効。ただしページ全体のアクセシビリティスナップショットやスクリーンショットはトークンを多く使うことがある。

恒常的な回帰テストはPlaywright TestコードをGit管理し、MCPは失敗時の対話的診断に限定する案を推奨する。

### Next.js専用MCPについて

個人製のNext.js／React MCPを追加するより、公式Next.jsドキュメント、TypeScript、ESLint、Playwright、既存の`artifact-design`系skillで十分な可能性が高い。実在性・保守性・供給網リスクを確認できないMCPは導入しない。

## 4.8 GitHub運用

### 候補：GitHub公式 MCP Server

- 提供元：GitHub公式 `github/github-mcp-server`
- 公式情報：<https://github.com/github/github-mcp-server>

| 項目 | 評価 |
|---|---|
| 導入価値 | ローカル開発だけなら低。Issue／PR運用開始後は中 |
| CLI代替 | `git`＋`gh` CLIでほぼ可能 |
| 難易度 | 低～中。GitHub認証とtoolset／権限限定 |
| コスト | OSS／GitHub API。GitHubプランやActions料金は別 |

Claude CodeからIssue、PR、レビュー、Actions状況を横断操作する場合に有効。現時点のローカル設計・実装では、`git`と`gh`の方が出力制御しやすいため後回しでよい。

導入する場合は、最初から全toolsetを有効にせず、read-onlyまたはissues／pull requests等の必要範囲だけを公開する。

## 4.9 最新ドキュメント取得

### 条件付き候補：Context7 MCP

- 提供元：Upstash運営のContext7
- 公式情報：<https://github.com/upstash/context7>

| 項目 | 評価 |
|---|---|
| 導入価値 | 中 |
| CLI代替 | 公式ドキュメント検索、Terraform／dbt公式MCPで可能 |
| 難易度 | 低～中。提供形態とAPI keyを確認 |
| コスト | 無料枠／有料条件を導入時に確認 |

ライブラリの現行ドキュメントを必要部分だけ取得できる場合は、Web検索より省トークンになる。一方、Google Cloud、AWS、Terraform、dbtには公式情報源を優先し、第三者サービスへコードや質問を送る際のプライバシー条件を確認する。

必須ではなく、Next.jsやPythonライブラリのAPI差分調査が頻発した時点で評価する。

---

## 5. 総合評価表

| 候補 | 工程 | 価値 | CLI代替 | 難易度 | 直接費用 | 推奨時期 |
|---|---|---:|---|---:|---|---|
| Terraform MCP Server | IaC仕様探索 | 高 | 可能 | 低～中 | 原則無料候補 | 今すぐ候補 |
| AWS Labs Documentation／Knowledge系 | AWS仕様探索 | 中～高 | 一部可能 | 低～中 | 原則無料候補、背後サービス要確認 | AWS着手時 |
| AWS Labs API操作系 | AWS操作 | 中 | 可能 | 高 | AWS利用料 | 必要時のみ |
| MCP Toolbox for Databases | BigQuery探索 | 中 | 可能 | 中 | OSS、BQ料金別 | 反復探索時 |
| Google Cloud BigQuery remote MCP | BigQuery探索・操作 | 要確認 | 可能 | 中～高 | 要確認＋BQ料金 | GA/適合確認後 |
| dbt MCP Server | dbt lineage・モデル操作 | 中～高 | 可能 | 中 | Platform機能は要確認 | dbt採用後 |
| Playwright MCP Server | UI対話診断 | 中～高 | 可能 | 低～中 | 無料 | サイトQA時 |
| GitHub MCP Server | Issue／PR／Actions | 中 | `gh`で可能 | 低～中 | 原則無料 | チーム運用時 |
| Context7 | 最新ライブラリ資料 | 中 | 可能 | 低～中 | プラン要確認 | 調査頻発時 |
| Looker Studio専用MCP | BI編集 | 確実な公式候補を確認できず | 手動・API | — | — | 非推奨 |
| Tableau Public専用MCP | BI編集 | 適合する公式候補は要確認 | 手動・Hyper API | — | — | 非推奨 |
| サンプル生成用MCP | データ生成 | 低 | 完全に可能 | — | — | 不要 |

---

## 6. 推奨するClaude Code skills

外部skillを多数入れるより、`.claude/skills/`配下に短いプロジェクト専用skillを作る方が、正確性とトークン節約の両方に効く可能性が高い。skill本文は巨大な知識集ではなく、ルーティングとチェックリストに限定し、詳細は既存docsへリンクする。

### 6.1 `dual-cloud-schema-review`

目的：

- BigQueryとAthenaの論理列・型・NULL性・粒度の差分確認
- BigQuery partition／clusterと、Athena Parquet／partitionのレビュー
- 予約語、TIMESTAMP精度、DECIMAL精度、partition列の扱いを確認

skillへ含めるもの：

- 比較チェックリスト
- DDL出力先
- 検証コマンド
- `docs/schema_design_base.md`等への参照

### 6.2 `data-quality-and-cost-gate`

目的：

- 行数、NULL率、一意性、参照整合性、金額一致を自動確認
- BigQuery dry runのbytes、Athena scanned bytesを記録
- コスト閾値超過時は実行前に停止して相談

「破壊操作」と「有料になり得る全表スキャン」の承認条件を1か所に固定できる。

### 6.3 `dbt-model-workflow`

dbt採用時のみ作成する。

- `source → staging → intermediate → mart`の命名
- model／schema test／unit test／exposureの完了条件
- 変更モデルだけをbuildするselector
- BigQuery／Athena両対応SQLの方針と例外

### 6.4 `dashboard-kpi-contract`

既存`dataviz` skillを置き換えず補完する。

- CVR、ROAS、CPA、LTV、リテンション、アシストの正式定義
- grain、分子、分母、除外条件、帰属モデル
- 公開BIに個人粒度を含めない条件
- BI値と検証SQLの照合手順

### 6.5 `deployment-safety`

- dev／prod相当のproject・account・region確認
- Terraform plan保存と要約
- destroy、IAM変更、公開バケット、予算アラートの承認条件
- 秘密情報をログ・Git・Tableau Publicへ出さない検査

### skill作成時の注意

- 既に存在する`dataviz`、`simplify`、`update-config`等と重複させない
- 1つのskillに全プロジェクト情報をコピーしない
- 常時読み込む説明は短くし、必要時だけ詳細docsを読む
- コマンドを固定しすぎず、GCP／AWSの対象環境を引数化する
- 外部skillはソース、ライセンス、更新履歴、インストールスクリプトをレビューしてから採用する

---

## 7. トークン節約と精度向上の具体策

## 7.1 `fewer-permission-prompts`の使い方

読み取り・検証に限定してallowlist化する。

候補：

- `rg`、`sed`、`find`、`wc`
- `git status`、`git diff`、`git log`
- `terraform fmt -check`、`terraform validate`、`terraform show`
- `dbt parse`、`dbt compile`、限定selectorの`dbt test`
- `bq show`、dry run、読み取りクエリ
- `aws sts get-caller-identity`、`aws ... describe-*`／`list-*`

自動許可を避ける候補：

- `terraform apply`、`terraform destroy`
- `gcloud ... delete`、`aws ... delete-*`
- IAM／bucket policy／public accessの変更
- BigQuery／Athenaの上限なしクエリ
- `npm install`や外部スクリプト実行を無条件に許可する設定

許可の回数を減らしても、変更範囲を広げないことが重要である。

## 7.2 大きな出力はファイルへ保存する

例：

```bash
terraform plan -out=.artifacts/tfplan
terraform show -json .artifacts/tfplan > .artifacts/tfplan.json
terraform show -no-color .artifacts/tfplan > .artifacts/tfplan.txt
```

Claude Codeは全JSONを読まず、resource change件数、create/update/delete、IAM、公開設定、コスト関連resourceだけを抽出して読む。

同様に：

- dbt：`target/manifest.json`全体ではなく`dbt ls --select state:modified+ --output json`
- pytest：完全ログではなく失敗テストと末尾サマリー
- BigQuery：query plan全体ではなくdry-run bytes、partition filter、上位stage
- Athena：QueryExecutionStatisticsの`DataScannedInBytes`と失敗理由
- サンプルデータ：データ本体ではなく`profile.json`／`quality_report.md`

`.artifacts/`、`target/`、一時抽出を`.gitignore`へ追加し、秘密情報を保存しない。

## 7.3 差分駆動で読む

- 作業開始：`git status --short`
- 変更確認：`git diff --stat` → 対象ファイルの`git diff`
- 大きなファイル：`rg -n`で対象箇所を絞ってから`sed`
- 生成物：ソースとチェックサムだけ確認し、Parquet本体を読ませない
- 再レビュー：前回指摘の周辺と新規差分だけを渡す

「リポジトリ全体を毎回説明する」運用を避け、`CLAUDE.md`には不変の短いルールとdocsへの索引だけを置く。

## 7.4 CLI出力を最初から小さくする

- `gcloud --format=json(...)`または`--format=value(...)`
- `bq --format=prettyjson show`後に必要keyだけ抽出
- `aws --query '...' --output json`
- `terraform show -json`から変更種別だけ抽出
- `gh ... --json field1,field2 --jq '...'`
- `dbt ls --select <changed-selector> --output name`

コマンドをClaudeに丸ごと再解釈させるより、機械的なフィルターはCLI側で行う。

## 7.5 MCPのtoolsetを絞る

MCPを導入する場合：

- GitHubはissues／pull requests等、必要toolsetだけ
- AWSはDocumentation系とAPI操作系を分離
- DBはread-only、dataset/schema限定
- 変更系toolをデフォルト無効
- 1ターンで全スキーマ／全ログを返さない
- ページサイズ、行数、期間、列を明示する

接続されているだけで多数のtool定義がコンテキストへ入る実装もあるため、利用しないMCPはプロジェクト設定から外すか、必要なセッションだけ有効にする。

## 7.6 Claude CodeとCodexの役割分担を定型化する

現在の方針に合わせ、依頼テンプレートを次の4点に固定する案を推奨する。

1. Claude Codeが基本方針と決定済み事項をファイル化
2. Codexへ対象ファイル、変更可能範囲、成果物、検証条件を指定
3. Codexはレビュー指摘と詳細実装をファイルへ保存
4. Claude Codeは全文の再説明を求めず、`git diff`と未決事項だけ確認

長い背景説明を各依頼に再掲せず、`docs/project_decisions.md`等の決定ログへ集約するとよい。

## 7.7 コスト安全策をツールより先に設定する

- BigQuery：maximum bytes billed、dry run、partition filter、予算アラート
- Athena：workgroupのper-query／workgroup上限、Parquet、partition、結果保存先
- GCP／AWS：dev専用project／account、予算通知、不要resourceの棚卸し
- Terraform：planに費用発生resourceがあれば明示的にレビュー

MCPは課金を自動的に防止しない。自然言語で「少量だけ」と依頼しても、生成SQLが全表スキャンになる可能性があるため、サービス側の強制上限を使う。

---

## 8. 段階的な導入提案

## 8.1 Stage 0：今すぐ

1. PATHと既存インストール状況を再確認
2. Google Cloud CLI、AWS CLI v2、Terraform CLIを公式手順で導入
3. dbtを採用するか決定し、採用時だけdbt Core／adapterを導入
4. `fewer-permission-prompts`を読み取り・検証コマンドへ適用
5. `.artifacts/`、検証レポート、差分駆動の運用を整備
6. プロジェクトローカルskillとして、まず`data-quality-and-cost-gate`と`dual-cloud-schema-review`を作成

この段階では外部MCPは既存`codex`のみでもよい。

## 8.2 Stage 1：IaC着手時

- Terraform MCP Serverを試験導入
- Registry検索の品質とトークン量をCLI／Web検索と比較
- `plan` / `apply`は引き続きCLI

効果が小さければ外してもプロジェクト実装に影響しない構成にする。

## 8.3 Stage 2：クラウド別実装時

- AWS：AWS Labs Documentation／Knowledge系だけを追加候補
- GCP：BigQueryメタデータ探索が多い場合だけMCP Toolboxをread-onlyで追加
- 変更操作はTerraform＋CLIを維持

## 8.4 Stage 3：dbtモデル増加時

- dbt MCPを評価
- lineage、model discovery、Semantic Layerを実際に使う場合のみ継続
- 小規模なうちはdbt artifactsの部分読みで代替

## 8.5 Stage 4：サイト・公開運用時

- Playwright MCPを対話的UI診断用に追加
- 回帰テストはPlaywright Testへ固定
- Issues／PR／Actions運用が増えた場合だけGitHub MCPを追加

---

## 9. 導入前チェックリスト

各MCP／skillについて以下を満たしてから導入することを提案する。

- 公式提供元または信頼できる保守主体か
- 最新releaseと最終更新日は許容範囲か
- ライセンスは利用目的に適合するか
- npm／uvx／Docker imageの配布元と固定versionを確認したか
- インストールスクリプトをレビューしたか
- 送信されるコード、SQL、schema、認証情報の範囲を把握したか
- read-onlyまたは最小toolsetで開始できるか
- ローカルstdioかremote HTTPか
- ログへtoken／credentialが出ないか
- MCP停止時もCLIで再現できるか
- 追加されたtool定義と応答が、実際にトークン削減へつながるか
- クラウド側の予算・クエリ上限がMCPと独立して設定されているか

---

## 10. 最終提案

本プロジェクトでは、**「公式MCPをたくさん入れる」より、「CLIを正本にし、短いローカルskillで手順を固定し、探索量が増えた工程だけMCPを足す」**構成を推奨する。

優先順位は次のとおり。

1. CLI／認証／コスト上限／検証レポートの整備
2. プロジェクト固有skill
3. Terraform MCP
4. AWS Documentation系
5. dbt MCPまたはBigQuery向けMCP
6. Playwright MCP
7. GitHub MCP、Context7

Looker Studio／Tableau Public編集、サンプルデータ生成、通常のGit操作には、現時点で追加MCPを導入する積極的な理由は小さい。導入候補は必ず小さな試験タスクで、正確性、所要時間、返却トークン、権限範囲をCLIと比較してから常設する案が安全である。
