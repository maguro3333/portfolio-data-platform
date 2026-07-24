# 決定ログ

このプロジェクトの確定事項を集約する。背景の再説明を避け、各作業はここを参照する。

## 2026-07-23 プロジェクト基本方針
- クラウド: GCP・AWS並行フル構築。AWS DWHは Athena+Glue。
- データ: EC購買 + GA4風行動ログ、数十万件規模。テーマはECサイト。
- BI: Looker Studio(iframe) + Tableau Public。個人粒度データはPublicに出さない。
- サイト: Next.js+Tailwind を軸に検討(Vercel無料枠)。コスト最優先。
- ダッシュボード: Phase1(全体KPI/マーケ/コンテンツ)→Phase2(RFM・LTV/コホート/購買ファネル)→Phase3(クロスセル1本)→Phase4(オムニチャネルは発展編)。

## 2026-07-23 役割分担・ツール方針
- Claude Codeが基本方針を先に作り、Codexがレビュー/詳細化。順序厳守。
- 外部MCPは増やさずcodex一本。CLIを正本、大出力は`.artifacts/`へ逃がす。
- Claude CodeモデルはOpus 4.8。CodexはChatGPT Plus利用枠。

## 2026-07-24 スキーマ確定7項目(Phase1+2)
1. **売上KPI**: 経営KPIの主指標は `recognized_revenue`(返品控除後)。gross/net/recognizedを分離保持。
2. **税・送料**: AOV/ROASの売上には含めない(商品純売上ベース)。税・送料は別カラムで order_total を構成。
3. **キャンセル/返金**: キャンセル 3〜5% + 全額返金 1〜2% を生成。部分返品は対象外。
4. **アトリビューション**: 30日lookback・セッション単位。方式は last non-direct と linear の2種。credit合計は注文ごとに1.00。
5. **RFM閾値**: 五分位(quintile)スコアを採用。同一snapshot内で算出。
6. **小集団抑制**: Public公開集計は customers >= 10 未満を抑制。
7. **データ期間**: 2024-01-01〜2025-12-31(731日、2年)。

## 2026-07-24 データ規模(基準ケース、無料枠内確認済み)
- 登録ユーザー40,000 / pseudo_id約52,000 / 商品800 / キャンペーン24 / コンテンツ180
- セッション約220,000 / イベント約135万 / 注文約10,800 / 注文明細約17,800
- コスト試算: BigQuery保存3〜6GB・月次クエリ約88GB、Athenaごく少額。すべて無料枠内(相談ライン8GB/700GB/100GBに未達)。

## 2026-07-24 アーキテクチャ市場適合性見直し(詳細は docs/architecture_review_market_fit.md)
背景: AWS Free Plan(無料・6か月・$200クレジット・Redshift等制限)の範囲で市場性を高める方針。Redshiftは制限+課金リスクで不採用。Athenaサーバーレス構成を「実務評価に耐える完成形」に引き上げる。
- **導入範囲: フル(P0+P1)** を採用(すべて無料):
  - Terraform(GCP/AWS両方のIaC)
  - dbt Core(両クラウド共通のCore→Mart変換の正本)
  - dbt tests + クラウド間KPI照合(データ品質・データ契約)
  - GitHub Actions + OIDC(CI/CD、鍵レス、public repo)
  - Apache Iceberg(fact_orders のみ。ACID更新/time travel/レイクハウス訴求)
  - サーバーレスオーケストレーション(AWS Step Functions+EventBridge+Lambda / GCP Workflows+Cloud Scheduler、各1本)
- **8つの要判断事項の確定**:
  1. AWS本編名称: "serverless lakehouse"(Iceberg採用のため)
  2. Iceberg範囲: fact_orders のみ
  3. 変換基盤: 両クラウドとも dbt Core に統一(GCPはdbt-bigquery、AWSはdbt-athena系)
  4. オーケストレーション: AWS Step Functions + GCP Workflows 各1本
  5. GitHubリポジトリ: Public(Actions無料、OIDCで鍵レス、秘密情報は置かない)
  6. Cloud Run Jobs: 採用(Cloud Functionsより現代的・コンテナ化)
  7. Redshift: **実行しない**。代わりに「Athena vs Redshift 選定比較ADR」を無料の成果物として作成
  8. Free Plan再確認: Terraform apply直前に公式で再確認しdecisions.mdに記録
- 変換層はdbt Coreで統一し、まずローカル(dbt-duckdb)で分析ロジック(RFM五分位/コホート/ファネル/アトリビューション)を検証してからクラウドへ展開する方針。
- 実装フェーズ順(Codex案): A土台(Terraform/zone/IAM/コストガード)→B変換・品質(dbt)→C CI/CD→Dオーケストレーション→E Iceberg→F(任意Redshift、今回は不採用)。

## 2026-07-24 ポートフォリオサイト方針
- サイト本体を先に構築し、AIエージェントは後追いで1機能として組み込む。
- 技術スタック: **Next.js + Tailwind CSS on Vercel(無料枠)**。
- デザイントーン: **Claude/Anthropic系の温かみのある暖色**(オレンジ/テラコッタ×ベージュ/クリーム)をキーカラーに。
- 具体的なデザイン方針・ページ内要素構成は Codex で詳細化する(Claude Codeが基本IA/方針を起草→Codexが詳細デザイン設計)。
- 作業ディレクトリ: `/Users/oda/portfolio-data-platform/web/` に Next.js プロジェクトを作成。
- 詳細デザインは `docs/site_design_detail.md`(Codex作成)を採用。パレット: canvas #F5EFE5 / terracotta #A9462C / GCP=sage #3F665A / AWS=amber #C97819 / dbt共通=terracotta。和文Noto Sans JP・欧文Manrope・コードIBM Plex Mono。ライト基調+限定ダーク。
- 初期リリース範囲: Home / About / Architecture / Data&Pipeline / Dashboards / Contact + AI Analystはロードマップ表記。ダッシュボードは一覧+代表1件、iframe URLはLooker(手動作成中)/Tableau(未着手)が揃うまでプレースホルダ。
- P0確定(2026-07-24): 顔写真は使わず**モノグラム/テキスト開始**。**職務経歴書PDFは公開しない**(About要点のみ、PDFは問い合わせ後に個別送付)。Contactは**メールリンク(mailto)方式で作成するが当面は非公開**(サイトはフリーランスエージェント/ここなら等のプラットフォーム経由で露出するためコンタクト導線は不要。ページ自体は作りいつでも公開できる状態にする)。メールアドレスは**非公開**(コードに直書きせず、公開時のみ Vercel 環境変数 `NEXT_PUBLIC_CONTACT_EMAIL` で注入)。GitHub URL未定(プレースホルダ)。

## コスト事前相談トリガー(いずれか該当で実行前に相談)
- BigQuery保存見込み8GB以上 / 月次クエリ700GB以上 / Athena月次スキャン100GB以上
- 基準件数の2倍以上への拡大、日次顧客snapshot等の行数1桁増設計
- NAT Gateway/常時稼働compute/Glue crawler定期実行/Provisioned Capacity追加
- 無料枠対象条件を公式資料で確認できない状態
