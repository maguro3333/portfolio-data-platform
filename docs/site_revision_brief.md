# サイト改訂ブリーフ(Claude Code)— マーケ排除・ドキュメント/ケーススタディ型へ

初期実装(web/)はマーケ/PR/キャッチコピー寄りだった。以下の方針で**要素構成・デザイン・テキストを作り直す**。Codexは本ブリーフと `docs/site_design_detail.md` を踏まえ、詳細要素設計を更新した上で `web/` を再実装する。

## 全体方針(最重要)
- 目的: **フリーランスの案件受託**。閲覧者は採用担当・エージェント・クライアント。
- トーン: **事実ベースのドキュメント/ケーススタディ**。一人称で淡々と。PRコピー・キャッチコピー・煽り・抽象的スローガンは**排除**。
  - 現状の「事業の問いを、運用できるデータ設計へ。」のようなヒーローコピーは**不要**。廃止する。
- 軸: 「**この人材が、どのような意図で・どのような流れを経て・このサンプルプロジェクトを実装したか**」を、**採用目線で判断しやすい**形で提示する。
- 情報密度: 各ページの**ファーストビュー(またはそれに準ずる位置)に実質情報**を置く。飾りのヒーローで一画面消費しない。
- デザインシステム(パレット/タイポ/コンポーネント)は既存(site_design_detail.md §3-4、暖色: canvas #f5efe5 / terracotta #a9462c / GCP=sage / AWS=amber)を**流用**。変えるのは構成・情報設計・文章のトーン。装飾は控えめ、可読性最優先。

## ページ別 要素構成(作り直し)

### HOME `/`
- 目的: **サイトマップ + 各ページへの導線**。
- 構成:
  - 冒頭に簡潔な説明文(数行): 誰が(小田航平/フリーランス データエンジニア)、これは何か(自作の GCP/AWS 二刀流 EC データ基盤デモの解説サイト)、何を見られるか。キャッチコピーにしない。
  - **各ページへのリンクカード**(About / Architecture / Data & Pipeline / Dashboards)。各カードに「そのページで何がわかるか」の1〜2行の事実説明。
  - 任意で「プロジェクト概要(at a glance)」の事実リスト(スタック・スコープ・規模)を簡潔に。誇張しない。
- ヒーロー装飾・スローガンは置かない。

### ABOUT `/about`
- 目的: **経歴**。職務経歴書に準拠した事実。
- 構成: 職務要約 / 活かせるスキル(Python・SQL、BigQuery、GA4・GTM、Looker Studio・Tableau 等)/ 略歴(所属・期間・担当)/ 強み。PDFは非公開。自己PRの誇張表現は避け、実績・担当範囲を事実で。

### ARCHITECTURE `/architecture`
- 目的: **デモプロジェクトの全体像 + このサイト自体の技術スタック/システム構成 + ワークフロー + 各要素の活用内容・用途の解説**。
- 構成:
  - デモプロジェクトの概要と**実装意図**(なぜ二刀流、なぜこの構成か)。
  - システム構成図: GCP版(GCS→BigQuery→dbt→Looker Studio)/ AWS版(S3→Glue→Athena(Parquet lakehouse)→dbt→Tableau)/ このサイト(Next.js on Vercel、後追いのAIエージェント)。
  - **ワークフロー**: 生成データ→クラウド投入→dbt変換→品質テスト→BI→サイト、の流れを順序立てて。
  - 各技術要素の**用途・選定理由**(BigQuery=warehouse / Athena=lakehouse、dbtで論理共通・物理最適化のみクラウド別、Terraform IaC、コストガード、方言吸収マクロ 等)。
  - AIエージェントはRoadmapとして事実ベースで(text-to-SQL、後追い)。

### DATA & PIPELINE `/data-pipeline`
- 目的: **サンプルデータの構成・データ定義・テーブル定義**、および**元データをどんな意図・内容で加工し各種データマート化したか**の解説。
- 構成:
  - サンプルデータの全体像(EC購買 + GA4準拠行動ログ、2年、規模)。
  - **テーブル定義**: Core のディメンション/ファクト(dim_users, dim_products, fact_orders, fact_order_items, fact_events, fact_sessions, fact_campaign_cost_daily, 等)を、主要カラム・型・粒度の表で。schema_design_detail.md / generator/schema_contract.yaml を根拠に正確に。
  - **加工意図とマート化の解説**: raw(全列string)→ staging(型・命名整備)→ intermediate/core(セッション/ファネル/アトリビューション導出)→ marts(mart_kpi_daily / mart_marketing_daily / mart_content_performance / mart_content_assists / mart_funnel_daily / mart_customer_rfm_snapshot(内部) / mart_rfm_segment_daily(公開) / mart_customer_cohort)。各マートが「どの問いに答えるためのものか・どの粒度か」を説明。
  - 品質テスト(141)・トライエンジン照合の事実も簡潔に。

### DASHBOARDS `/dashboards`
- 目的: 各種ダッシュボードと、**それらが活用するデータ/参照テーブル(マート)**の提示。
- 構成:
  - **プルダウン(select)でダッシュボードを切替**できるUIが理想(全体KPI/マーケ/コンテンツ/RFM/コホート/ファネル)。
  - 選択中のダッシュボードごとに: 埋め込み枠(Looker Studio / Tableau Public。URL未確定のうちはプレースホルダ/Coming soon)+ **参照している mart テーブル**と主要指標の明記。
  - どのダッシュボードがどのマート/指標に対応するかを採用者が追える形に。

### CONTACT `/contact`
- 現状維持(mailto・noindex・nav非表示)。変更不要。

## Codexへの依頼
1. 本ブリーフに沿って `docs/site_design_detail.md` の該当箇所(§5ページ構成・§7コピー)を**ドキュメント/ケーススタディ型に改訂**(マーケ表現除去、事実・意図・フロー重視)。デザインシステム(§3-4)は流用。
2. `web/` の各ページ・共通コンポーネント・`src/lib/site-data.ts` を**作り直す**。技術的事実は docs(decisions.md, architecture_review_market_fit.md, schema_design_detail.md, dashboard_design.md, generator/schema_contract.yaml)を根拠に正確に。
3. Dashboards は select でダッシュボード切替 + 参照マート明記のUIにする。
4. ネットワーク制限のため npm/build は実行しない(Claude Codeが検証)。応答は簡潔に。git diff --check を通す。
