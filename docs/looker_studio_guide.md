# Looker Studio ダッシュボード作成ガイド(GCP / BigQuery ec_mart)

BigQuery `ec_mart` のマートを Looker Studio に接続し、ポートフォリオ用ダッシュボードを作る手順。Looker Studio はレポート自動生成APIが無いため、データソース接続はリンクで省力化し、チャートは本ガイドのレシピどおりUIで配置する。

前提: オーナーのGoogleアカウントでログイン、プロジェクト `psyched-camp-502314-m3`。

---

## 0. データソースの接続(手動・確実)

Looker StudioのリンクAPIは新規レポートへのデータソース自動接続が不安定なため、手動で追加する。

1. <https://lookerstudio.google.com> → 左上「作成」→「レポート」
2. データ追加画面で「BigQuery」コネクタ → 認可を承認
3. マイプロジェクト → `psyched-camp-502314-m3` → データセット `ec_mart` → テーブル `mart_kpi_daily` → 「追加」
4. 追加のマートは「リソース → 追加済みのデータソースの管理 → データソースを追加」で、`ec_mart` の各テーブルを同様に追加:
   - `mart_marketing_daily` / `mart_funnel_daily` / `mart_customer_cohort` / `mart_rfm_segment_daily` / `mart_content_performance`(必要に応じ `mart_content_assists`)

### データソースの重要設定
- 各データソースの認証情報は **「オーナーの認証情報」**(既定)にする。閲覧者(ポートフォリオ訪問者)がBigQuery権限を持たなくても表示できる。
- データの更新頻度(データの鮮度)は 12時間キャッシュのままでよい(BigQueryクエリ課金と負荷を抑制)。マートは小さいため無料枠内。

---

## 1. 計算フィールド(データソースごとに定義)

Looker Studio では比率は素の集計を割って定義する(事前集計しない)。各データソースで「フィールドを追加」。

**mart_kpi_daily**
- `CVR` = `SUM(orders)/SUM(sessions)`(表示形式: パーセント)
- `AOV` = `SUM(recognized_revenue)/SUM(orders)`(通貨)
- `エンゲージ率` = `SUM(engaged_sessions)/SUM(sessions)`
- `粗利率` = `SUM(gross_profit)/SUM(recognized_revenue)`
- `新規顧客率` = `SUM(new_customers)/SUM(purchasers)`

**mart_marketing_daily**
- `ROAS` = `SUM(attributed_revenue_last_touch)/SUM(cost)`
- `CPA` = `SUM(cost)/SUM(new_customers)`
- `CTR` = `SUM(clicks)/SUM(impressions)`
- `CPC` = `SUM(cost)/SUM(clicks)`
- `セッションCVR` = `SUM(purchasing_sessions)/SUM(sessions)`

**mart_rfm_segment_daily**
- `平均LTV` = `SUM(total_revenue)/SUM(customers)`

---

## 2. ページ別レシピ

各ページ上部に期間フィルター(コントロール → 期間設定、既定フィールド `metric_date`)と、`device_category`・`source`・`medium`・`customer_type` のプルダウン(ディメンションコントロール)を置く。

### Page 1 — 全体KPI(データソース: mart_kpi_daily)
- スコアカード×7: `sessions` / `orders` / `recognized_revenue` / `CVR` / `AOV` / `new_customers` / `粗利率`(前期比較を有効化)
- 時系列グラフ: ディメンション `metric_date`、指標 `recognized_revenue` と `orders`(2軸コンボ)
- 円/ドーナツ: `device_category` 別 `sessions`
- 表(棒付き): ディメンション `source`、指標 `sessions`, `orders`, `CVR`, `recognized_revenue`

### Page 2 — デジタルマーケティング(mart_marketing_daily)
- スコアカード: `cost` / `ROAS` / `CPA` / `セッションCVR`
- 散布図: X=`cost`、Y=`ROAS`、バブルサイズ=`new_customers`、ディメンション=`campaign_id`
- 時系列: `cost` と `attributed_revenue_last_touch`(コンボ)
- 表: ディメンション `source`+`medium`、指標 `sessions`, `セッションCVR`, `cost`, `CPA`, `ROAS`
- ヒートマップ(ピボット): 行 `device_category` × 列 `source`、指標 `セッションCVR`

### Page 3 — コンテンツ(mart_content_performance)
- スコアカード: `content_view_sessions` / `product_click_sessions` / `direct_purchase_orders` / `direct_purchase_revenue`
- 散布図: X=`content_view_sessions`、Y=`direct_purchase_orders`、色=`content_group`
- 表: ディメンション `content_id`+`content_type`、指標 `content_view_sessions`, `product_click_sessions`, `direct_purchase_revenue`
- (アシスト貢献は mart_content_assists を別データソースで追加すると更に厚くできる)

### Page 4 — 購買ファネル(mart_funnel_daily)
- 棒グラフ(横): ディメンション `funnel_event_name`、指標 `reached_sessions`、並び順は `funnel_step` 昇順(ファネル代替)
- スコアカード: `step_conversion_rate`(段階選択で)
- ヒートマップ(ピボット): 行 `device_category` × 列 `funnel_event_name`、指標 `reached_sessions`
- セグメント比較: `customer_type` でフィルターしモバイル/PCの段階CVR差を表示

### Page 5 — コホート・リテンション(mart_customer_cohort)
- ピボットテーブル(ヒートマップ書式): 行 `cohort_month`、列 `months_since_first`、指標 `customer_retention_rate`(条件付き書式で色付け=コホートヒートマップ)
- 折れ線: X=`months_since_first`、指標 `cumulative_repeat_rate`、内訳ディメンション `acquisition_source`
- 表: `cohort_month` 別 `cohort_customers`, `cumulative_revenue`

### Page 6 — CRM / RFM(mart_rfm_segment_daily)
- 期間はコントロールで `snapshot_date` を最新月に絞る
- 棒グラフ: ディメンション `rfm_segment`、指標 `customers`
- 表: `rfm_segment` 別 `customers`, `平均LTV`, `avg_frequency_orders`, `avg_recency_days`, `avg_order_value`
- 内訳: `acquisition_source` 別のセグメント構成(100%積み上げ棒)
- ※このマートは小集団抑制済み(customers>=10)。顧客個人粒度は含まない。

---

## 3. デザインの指針(市場評価を上げる)
- 1ページ=1つの問い。上段スコアカード→中段トレンド→下段明細の縦構成。
- 色は意味に割り当てる(1系統のアクセント+グレー)。無関係な多色を避ける。
- 全ページ共通ヘッダー(タイトル・期間・更新日)とフィルターを揃える。
- 数値の書式(通貨¥、パーセント、桁区切り)を統一。

---

## 4. ポートフォリオサイトへの埋め込み(iframe)
1. レポート右上「共有」→ リンク共有を **「リンクを知っている全員(閲覧者)」** に設定。
2. 「共有」→「レポートを埋め込む」→ 埋め込みを有効化 → iframe コードをコピー。
3. Next.js ポートフォリオサイトに iframe を配置(後工程)。
   - 例: `<iframe src="https://lookerstudio.google.com/embed/reporting/<REPORT_ID>/page/<PAGE_ID>" width="100%" height="900" frameborder="0" allowfullscreen></iframe>`
- 埋め込み後もデータソースはオーナー認証情報で動くため、訪問者はBigQuery権限不要。
- 閲覧のたびにBigQueryクエリが走るが、マートは小さくキャッシュ(12h)も効くため無料枠内。

---

## 5. コスト注意
- Looker Studio 経由の BigQuery クエリは `ec_mart`(合計約54MB)のみ参照。1ページ表示あたり数十MBスキャン、キャッシュ有。想定月間スキャンは無料枠(1TB/月)に対し十分小さい。
- 万一 `ec_raw`(422MB)や `fact_events` を直接データソースにすると増えるので、**BIは必ず `ec_mart` を参照**する。
