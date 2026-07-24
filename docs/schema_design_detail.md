# Phase 1+2 スキーマ詳細設計・基本方針レビュー（提案）

## 1. 本書の位置づけ

本書は、`docs/schema_design_base.md`を基本方針としてレビューし、Phase 1（全体KPI／マーケティング／コンテンツ）とPhase 2（CRM・LTV/RFM／コホート／購買ファネル）に必要な論理スキーマ、物理設計、データ生成仕様、容量・コスト見積もりを詳細化した提案である。

対象外：

- Phase 3のクロスセル専用テーブル（`fact_order_items`から都度または将来マート化）
- Phase 4のオムニチャネル
- 部分返品、在庫履歴、価格履歴、店舗、POS

DDL：

- BigQuery：`sql/bigquery/01_core.sql`、`sql/bigquery/02_marts.sql`
- Athena/Glue：`sql/athena/01_core.sql`、`sql/athena/02_marts.sql`

DDL内の`PROJECT_ID`、`CORE_DATASET`、`MART_DATASET`、`DATABASE_NAME`、`BUCKET_NAME/PREFIX`はデプロイ時に置換するテンプレート値である。DDLはテーブル契約を示すものであり、マートの変換SQLそのものは別途作成する想定とする。

---

## 2. 基本方針のレビュー

## 2.1 全体評価

Raw/Staging → Core → Martの3層、GCP/AWS間で論理契約を共通化する方針、個人粒度RFMをPublicへ出さない方針は妥当と考える。特に広告費を日×キャンペーン粒度で保持し、注文・イベント粒度へ展開しない方針は維持を推奨する。

一方、基本方針のままDDL化すると粒度や金額定義が曖昧になる箇所があるため、以下の補正を提案する。

## 2.2 レビュー指摘と対応案

| 重要度 | 論点 | 懸念 | 詳細設計での提案 |
|---|---|---|---|
| 高 | `net_sales`の意味 | 税・送料・返品を含むか判断できず、AOVやROASが不一致になる | `gross_sales`、`discount_amount`、`item_net_sales`、`tax_amount`、`shipping_amount`、`order_total`、`recognized_revenue`を分離 |
| 高 | `fact_sessions.order_id` | 1セッションに複数注文があり得るため、1注文ID列は粒度と矛盾する | `order_id`を除き、`order_count`と`session_revenue`を保持。注文への明細結合は`fact_orders.session_id`から行う |
| 高 | ファネルの定義 | `session_id+順序`だけでは、同じイベントの反復や異なる商品の混在で数が変わる | `event_sequence`を追加。セッション単位の順序必須ファネルとし、商品カテゴリは最初に到達した対象商品で固定する案 |
| 高 | 日付・時刻 | UTCと表示日付の境界が未定義 | TIMESTAMPはUTC、`event_date`等の業務日付は`Asia/Tokyo`で導出する案 |
| 高 | Martの粒度 | 「主要ディメンション」「セグメント」「属性」が未確定で、多重集計の危険がある | 各DDLでsource/medium/device/customer_type/category等を明示 |
| 高 | コホート未成熟判定 | コホート月だけでは各セルが観測可能か判断しにくい | `observable_customers`を追加し、未成熟期間の`retained_customers`・売上・率をNULLにする |
| 高 | 個人データ公開 | 匿名IDでも行動履歴の公開は再識別リスクが残る | Publicは`mart_rfm_segment_daily`のみ。小集団抑制を導入 |
| 中 | 商品SCD非採用 | 商品名・カテゴリ変更時に過去分析が現在値へ書き換わる | Phase 1+2では変更しない生成ルールを置く。変更を生成するならSCD2へ昇格 |
| 中 | 会員ランク履歴 | `valid_to`の包含／排他、期間重複が未定義 | `[valid_from, valid_to)`の半開区間、現行行はNULL、同一ユーザーで重複禁止 |
| 中 | IDブリッジ | 1対1でない方針は正しいが、どの時点の対応を使うか未定義 | `[valid_from, valid_to)`と`identity_source`を追加。イベント時刻が期間内の行だけ結合 |
| 中 | アトリビューション | 対象接点とlookbackが未定義 | 購入前30日、セッション単位、directの扱いを固定。creditは注文ごとに1.00へ一致 |
| 中 | Content assists粒度 | 「コンテンツ×購入期間」だけでは帰属方式を区別できない | `purchase_date × content_id × attribution_model × lookback_days` |
| 中 | Campaign cost | source/medium/campaign名変更や自然流入との結合が曖昧 | 有料キャンペーンはstableな`campaign_id`で結合。自然流入は費用0行を作らず、Martで0扱い |
| 中 | BigQuery制約 | PK宣言をデータ品質保証と誤認しやすい | BigQueryのPKは`NOT ENFORCED`。dbt/SQLテストを正とする |
| 中 | Athena制約 | Glue DDLではPK/NOT NULLを強制できない | ETL検証とParquet生成時schema検査を正とする |
| 低 | `date`列名 | 関数・予約語との混同が起きやすい | `calendar_date`へ変更 |
| 低 | `os`列名 | 製品間の意味が曖昧 | `operating_system`へ変更 |

## 2.3 決定を求める項目

以下は実装前にClaude Code側で確定することを提案する。

1. **売上KPI**：経営売上を`recognized_revenue`とするか、`item_net_sales`とするか
2. **税・送料**：AOV、ROASの売上に含めるか
3. **キャンセル／返金**：Phase 1+2ではキャンセルのみか、全額返金まで生成するか
4. **アトリビューション**：30日lookback、directの除外／上書きルール
5. **RFM閾値**：全顧客の五分位か、固定業務閾値か
6. **小集団抑制**：Public用集計を`customers >= 10`とするか
7. **データ期間**：以下で提案する2年間を採用するか

---

## 3. 共通論理契約

## 3.1 型マッピング

| 論理型 | BigQuery | Athena/Glue | 用途 |
|---|---|---|---|
| string | `STRING` | `STRING` | ID、名称、区分 |
| integer | `INT64` | `BIGINT` | 件数、sequence、日数 |
| money | `NUMERIC` | `DECIMAL(18,2)` | JPY金額。小数2桁へ正規化 |
| rate | `NUMERIC` | `DECIMAL(18,6)` | CVR、credit、retention |
| boolean | `BOOL` | `BOOLEAN` | フラグ |
| date | `DATE` | `DATE` | 業務日付 |
| timestamp | `TIMESTAMP` | `TIMESTAMP` | UTC時刻 |

BigQuery `NUMERIC`はAthena `DECIMAL(18,2)`より広いが、論理契約では金額をprecision 18、scale 2へ制限する。生成・変換テストで小数桁と範囲を強制する。

## 3.2 共通規則

- IDはクラウド間で同じ決定的文字列を使用する
- 通貨はPhase 1+2では`JPY`のみ
- 金額は浮動小数ではなくDecimalで生成・計算する
- `created_at`はデータ行の生成／ロード時刻、業務イベント時刻とは分離する
- source/mediumは小文字正規化し、欠損は`(direct)` / `(none)`等の合意済み値へ正規化する
- MartのディメンションNULLは、意味がある場合に`(not set)`等へ統一してBIの欠落を防ぐ
- 率は可能な限りBIで再計算せず、分子・分母も保持する
- Coreの派生列は、クラウド間で同じテストベクトルを使って照合する

## 3.3 金額整合式

完成注文について、許容誤差0.01円相当で以下を成立させる。

```text
fact_order_items.item_gross_sales
  = quantity * unit_list_price

fact_order_items.item_discount_amount
  = item_gross_sales - item_net_sales

fact_order_items.item_cost
  = quantity * unit_cost

fact_order_items.item_gross_profit
  = item_net_sales - item_cost

fact_orders.gross_sales
  = SUM(item_gross_sales)

fact_orders.discount_amount
  = SUM(item_discount_amount)

fact_orders.item_net_sales
  = SUM(item_net_sales)

fact_orders.order_total
  = item_net_sales + tax_amount + shipping_amount
```

`recognized_revenue`と`gross_profit`は、キャンセル／返金方針確定後に契約を固定する。DDLでは列を確保している。

---

## 4. 物理設計提案

## 4.1 BigQuery

### Dataset案

- `ec_raw`：生成CSVの外部／ロード直後
- `ec_staging`：型、重複、名称正規化
- `ec_core`：Core＋Intermediate
- `ec_mart`：BI参照

環境を分ける場合はprojectを分けるか、dataset接頭辞に`dev_`を付ける。公開BI用サービスアカウントは`ec_mart`の必要tableだけをread可能とする。

### Partition

- 大規模ファクト：業務日付の日次partition
- RFM：`snapshot_date`
- コホート：`cohort_month`
- 小規模dimension：partitionなし
- 全日次factに`require_partition_filter=TRUE`

`fact_order_items.order_date`は注文ヘッダーから複製する。これは論理粒度を変えず、注文期間フィルターで明細の全走査を避けるための物理補助列である。

### Cluster

クラスタ列は、頻出filter／join列から最大4列に限定した。例：

- events：`event_name, session_id, user_pseudo_id, campaign_id`
- orders：`user_id, order_status, session_id, device_category`
- marketing mart：`campaign_id, source, medium, device_category`

この規模ではクラスタによる削減が限定的な場合もある。運用後にquery planを確認し、効果のないクラスタは維持コストを避けて削る。

## 4.2 Athena／Glue

### 保存形式

- Raw：CSV＋gzipでも可
- Staging/Core/Mart：Parquet＋Snappy
- Hive-style path：`table/event_date=2025-01-01/part-00000.parquet`
- schema evolutionは追加列を末尾へ追加する方向を基本とする

### Partition projection

DDLでは日付partition projectionを提案している。Glue crawlerや`MSCK REPAIR TABLE`を毎回動かさず、日付条件からS3 pathを解決できる。

注意：

- Athenaではpartition列が通常のParquet列とは別管理になる。`bridge_user_identity`だけは論理列`valid_from TIMESTAMP`を保持しつつ、物理partition補助列`valid_from_date DATE`を追加している。この補助列はSemantic/Martへ公開せず、GCP/AWSの論理契約比較から除外する
- projectionの開始日`2024-01-01`はデータ期間確定後に変更する
- queryにはpartition列の条件を必須とする運用を設ける
- AthenaにはBigQueryの`require_partition_filter`相当のtable強制がないため、workgroup、SQL review、dbt macroで補う
- partition projectionは存在しないpartitionも論理的に列挙し得るため、範囲を過度に広げない

### 小ファイル

提案件数ではeventsでも1日平均約1,850行であり、日次Parquetは小さくなる。ポートフォリオの分かりやすさと日付pruningを優先し日次partitionをDDL案としたが、次を守る。

- 1日につき原則1 Parquetファイル
- 同一partitionへ小ファイルを追記し続けない
- 生成後にcompactする
- 行数が大きく増える場合は日次partitionを維持しファイルサイズ128～512MBを目安にする
- 現状の小規模でAthenaのplanning遅延が問題になる場合は、`event_month`等の月次物理partitionへ変更する。この変更は論理列・指標を変えない

### Workgroup

- query result用S3 prefixをデータ本体と分離
- encryptionを有効化
- per-query data scan limitを設定
- CloudWatch metrics／予算通知を設定
- BI用workgroupと開発用workgroupを分離する案

---

## 5. データ生成仕様（ドラフト）

## 5.1 基準ケース

| 項目 | 提案値 |
|---|---:|
| データ期間 | 2024-01-01～2025-12-31（731日） |
| 登録ユーザー | 40,000 |
| anonymous device ID (`user_pseudo_id`) | 約52,000 |
| 商品 | 800 |
| キャンペーン | 24 |
| コンテンツ | 180 |
| セッション | 約220,000 |
| イベント | 約1,350,000 |
| 注文 | 約10,800（キャンセル等を含む） |
| 注文明細 | 約17,800 |

seed固定で、同一設定からGCP/AWSへ同一データを出力する。クラウド別に生成し直さない。

## 5.2 テーブル別目標行数

| テーブル | 目標行数 | 算出・備考 |
|---|---:|---|
| `dim_date` | 731 | 2年 |
| `dim_users` | 40,000 | 登録会員。購入しない会員も含む |
| `dim_membership_rank_history` | 50,000～60,000 | 平均1.25～1.5履歴/会員 |
| `bridge_user_identity` | 45,000～60,000 | 複数deviceとlogin前後を反映 |
| `dim_products` | 800 | 8～12 L1カテゴリ、各3～8 L2 |
| `dim_campaign` | 24 | paid中心。常時＋季節キャンペーン |
| `dim_content` | 180 | blog 55%、sns 30%、lp 15%の目安 |
| `fact_orders` | 約10,800 | 全sessionの約4.9%。完成注文は約10,300 |
| `fact_order_items` | 約17,800 | 1注文平均1.65明細 |
| `fact_events` | 約1,350,000 | 1session平均約6.1 events |
| `fact_sessions` | 約220,000 | 1 pseudo ID平均約4.2 sessions |
| `fact_campaign_cost_daily` | 5,000～8,000 | campaign active日のみ |
| `int_order_touchpoints` | 20,000～27,000 | 完成注文平均2.0～2.5 eligible touchpoints |
| `mart_kpi_daily` | 20,000～45,000 | 実在するdimension組合せのみ |
| `mart_marketing_daily` | 30,000～70,000 | campaign active組合せ＋organic |
| `mart_content_performance` | 50,000～100,000 | 公開後かつ閲覧のある日だけ |
| `mart_content_assists` | 10,000～30,000 | assistのあるcontent/date/modelだけ |
| `mart_funnel_daily` | 80,000～180,000 | 0件組合せを作らない |
| `mart_customer_rfm_snapshot` | 100,000～160,000 | 月末snapshot、当時点購入者のみ |
| `mart_rfm_segment_daily` | 2,000～8,000 | snapshot×segment×属性 |
| `mart_customer_cohort` | 1,000～4,000 | 実在するcohort/経過月/属性 |

Martは密な直積を生成しない。たとえば全日付×全キャンペーン×全deviceを0埋めすると、不要な行と誤った平均を増やす。

## 5.3 ユーザーとID

### ユーザー属性

人口統計はポートフォリオの分析要件に必要な範囲だけ生成する。実在人物由来の名前、住所、メール、電話番号は生成しない。

例：

- region：関東35%、近畿18%、中部15%、九州10%、東北7%、中国6%、北海道5%、四国4%
- age_band：18-24 10%、25-34 25%、35-44 25%、45-54 20%、55-64 13%、65+ 7%
- gender：過度に購買傾向を決定しない。`unknown`も含める
- registration_channel：organic 35%、paid search 25%、social 15%、email/referral/other 25%

属性は行動確率へ弱く影響させるに留め、性別や地域だけで極端な購入傾向を作らない。

### Identity

- 1人1device：70%
- 2 devices：25%
- 3 devices以上：5%
- セッション開始時は未ログイン、途中でloginして`user_id`が付くケースを生成
- bridge期間外のイベントへ会員IDをbackfillしない
- anonymous-only visitorも生成し、全pseudo IDが会員に紐づく状態を避ける

## 5.4 セッション

ユーザー／deviceごとのsession数は負の二項分布またはGamma-Poisson混合を推奨する。単純Poissonより、少数の高頻度訪問者と多数の低頻度訪問者を自然に表現できる。

基準：

- 約52,000 pseudo IDs
- 約220,000 sessions
- 平均4.2 sessions/pseudo ID
- 中央値2～3
- 上位5%は15回以上
- bot的な極端値は上限60回程度でclip

時間帯：

- 平日：7～9時、12時、20～23時に山
- 休日：10～13時、20～23時に山
- 深夜帯は少量
- timestampはUTC保存、生成確率はJST基準

device：

- mobile 68%
- desktop 27%
- tablet 5%

mobileはsession数が多い一方、基準CVRをdesktopより低くする。差を固定値にせず、channelや新規／既存との交互作用を持たせる。

## 5.5 イベント

### 基本イベント

- `session_start`
- `page_view`
- `view_item`
- `add_to_cart`
- `begin_checkout`
- `purchase`
- コンテンツページ閲覧／商品クリックを`page_view`とcontent/product列で表現

1sessionあたりevent数：

- 平均：約6.1
- 中央値：4～5
- 90パーセンタイル：12～15
- 上限：80程度

event生成は完全独立にせず、状態遷移として生成する。

```text
session_start
  -> page_view
  -> content view / category view / search
  -> view_item (0..n)
  -> add_to_cart (0..n)
  -> begin_checkout (0..1)
  -> purchase (0..1; 稀に2注文)
```

同じsession内で`event_timestamp`と`event_sequence`が矛盾しないようにする。再読み込みや複数商品閲覧による同名eventの反復は許容する。

### Funnel目標

全220,000 sessionsに対する目安：

| 到達段階 | Session数 | 前段階比 | 全session比 |
|---|---:|---:|---:|
| `view_item` | 約100,000 | — | 45% |
| `add_to_cart` | 約28,000 | 28% | 12.7% |
| `begin_checkout` | 約17,000 | 61% | 7.7% |
| `purchase` | 約10,500 | 62% | 4.8% |

定義：

- カート放棄率：`1 - purchase sessions / add_to_cart sessions` ≈ 62.5%
- Checkout放棄率：`1 - purchase sessions / begin_checkout sessions` ≈ 38%
- Session CVR：`purchase sessions / all sessions` ≈ 4.8%

このCVRは一般ECとしてやや高めに見える可能性があるため、ポートフォリオ上は既存顧客比率やブランド特性を説明する。より一般的な2～3%へ下げる場合、RFM分析に必要な注文数を確保するためsession数を増やすか、対象期間を延ばす必要がある。

### Event重複

現実的な品質問題として0.1～0.3%の重複送信をRawへ混ぜ、Stagingで`event_id`により排除する案を提案する。Coreの`fact_events`は重複排除済み件数とする。

## 5.6 商品・価格・注文

### 商品

- 8～12のL1カテゴリ
- カテゴリ内人気度はZipf／Pareto型
- 上位20%の商品が売上60～75%を占める
- list priceはカテゴリ別log-normal分布
- standard costはlist priceの35～70%
- Phase 1+2では商品属性とlist priceを期間中に変更しない

### 注文

- 完成注文：約10,300
- キャンセル：約3～5%
- 全額返金を含める場合：完成後注文の1～2%。部分返品は対象外
- 購入者：約7,500
- 購入者あたり平均注文：約1.4
- 1回のみ：約74%
- 2回：約18%
- 3回以上：約8%

明細：

- 1明細：58%
- 2明細：28%
- 3明細：10%
- 4明細以上：4%
- quantityは通常1、消耗品カテゴリで2以上が増える

AOVはカテゴリmixに依存させ、注文全体では8,000～12,000円程度を目安とする。極端な値を少数含めるが、箱ひげ図を壊すほどの無制限な外れ値は避ける。

### Repeat

2回目購入までの日数をlog-normal／Weibullで生成し、中央値45～75日程度を目安にする。消耗品は短く、耐久品は長くする。これにより初回購入カテゴリ別コホートに説明可能な差が出る。

## 5.7 季節性

基準trafficへ乗算係数を掛け、日ごとの期待session数を作る。

例：

| 要因 | 係数案 |
|---|---:|
| 通常平日 | 1.00 |
| 土日祝 | 1.10～1.20 |
| 給料日前後（25日付近） | 1.05～1.12 |
| Golden Week | 1.15 |
| 夏季セール | 1.25～1.45 |
| Black Friday相当 | 1.60～2.00 |
| 年末商戦 | 1.35～1.70 |
| 1月初旬 | カテゴリにより0.8～1.3 |

単純にtrafficだけを増やさず、セール時は次も連動させる。

- paid sessionと広告費が増える
- discount率が上がる
- CVRが上がる
- AOVまたは粗利率は下がる場合がある
- 新規顧客比率が増え、そのコホートのretentionが通常より低いケースを作る

これにより「売上増加＝顧客価値改善ではない」という分析が可能になる。

## 5.8 Channel・Campaign・広告費

session構成案：

| Channel | 比率 |
|---|---:|
| organic search | 30% |
| paid search | 22% |
| direct | 18% |
| organic social | 10% |
| paid social | 8% |
| email | 7% |
| referral / other | 5% |

channel別CVRには説明可能な差を持たせる。

- email／direct：既存顧客が多く高CVR
- paid social：新規が多く低CVRだがassistが多い
- paid search：意図が強く中～高CVR
- organic search：content接触とロングテール商品閲覧が多い

Campaign：

- always-on campaign 6～8本
- 季節campaign 10～12本
- content／新商品campaign 4～6本
- 同時期に完全に同じ効果を持たせず、ROASの良否を分布させる

広告指標：

- CTR：search 2～6%、social 0.5～2%
- CPC：campaign/platform別log-normal
- cost = clicks × CPCを基本とし、日次予算上限でclip
- impressions ≥ clicks ≥ attributed purchase sessions
- 費用のないorganic/directにはcost factを作らない

## 5.9 Content

- blog：長いengagement、商品クリック率は中、assistが多い
- sns：短いengagement、初回流入が多い、直接CVは低め
- lp：閲覧数はcampaign依存、商品クリック／直接CVが高め
- 公開後7日間にピーク、その後指数減衰
- evergreen contentは緩い減衰とorganic流入を持つ
- content target categoryと閲覧／購入categoryに強いが完全ではない相関を持たせる

アシストは購入前30日内のeligible sessionを対象とし、同一contentの同一session内反復は1 touchpointへまとめる案を提案する。

## 5.10 Membership rank／RFM

会員ランク例：

- bronze：登録時
- silver：過去365日2注文または一定売上
- gold：過去365日4注文または一定売上
- platinum：上位少数

rank履歴は注文発生後にのみ変化させ、分析時点より未来の注文を参照しない。rank低下を生成する場合は年次判定等の明確な規則が必要になる。

RFM：

- snapshotは各月末
- その日以前のcompleted orderのみ
- Recency：snapshot date - last completed order date
- Frequency：観測開始または直近365日のcompleted orders
- Monetary：同じwindowのrecognized revenue
- 五分位scoreは同一snapshot内で算出

比較可能性を優先するなら固定業務閾値、分布の見栄えを優先するなら五分位が向く。ポートフォリオでは両者の違いを説明し、採用は一方に固定する。

## 5.11 Cohort

- cohort：初回completed orderの月
- period：calendar month差
- period retention：該当経過月に1回以上購入した顧客 / cohort customers
- cumulative repeat：初回後、該当月末までに1回以上再購入した顧客 / cohort customers
- 当該経過月がデータ終端まで完了していない場合は未成熟

`cohort_customers`は列方向で不変であること、retainedはcohort customers以下であることをテストする。

---

## 6. データ品質テスト

## 6.1 Core

| テスト | 合格基準案 |
|---|---|
| PK一意性・NULL | 0件 |
| FK orphan | 0件。ただしnullable列は除外 |
| event重複 | Coreで`event_id`重複0件 |
| timestamp/date | JST変換後の日付がpartition dateと一致 |
| session範囲 | start <= event <= end |
| event sequence | session内で一意かつtimestamp順 |
| order item合計 | 0.01以内でheaderと一致 |
| purchase/order照合 | completed orderの98%以上。未照合理由を別集計 |
| campaign cost | cost >= 0、impressions >= clicks |
| touchpoint credit | order/modelごとに1.00 ± 0.000001 |
| rank履歴 | user内で期間重複0件 |
| identity履歴 | 同じpairで期間重複0件 |

purchase/order照合を100%にしない案は、GA4計測漏れを現実的に再現する場合だけ採用する。データ基盤の正解データとして単純化するなら100%でもよい。

## 6.2 Mart

- KPI Martの日次orders／revenue合計がCoreと一致
- Marketing cost合計がcost factと一致
- Funnelで後段reached sessionsが前段以下
- CVR分母0はNULL
- RFMにsnapshot後注文が含まれない
- RFM Public集計が内部snapshotと一致
- Public集計の顧客数が最小集団基準以上
- Cohort未成熟セルがNULL
- Cohortの累積売上・累積注文が減少しない
- attribution model別の全帰属売上がeligible order revenueと一致

---

## 7. 容量概算

## 7.1 前提

実データを生成する前の概算であり、文字列長、Parquet dictionary効率、BigQuery logical bytes、Raw保持期間で変動する。安全側に幅を持たせる。

| 層／対象 | 行数目安 | 容量目安 |
|---|---:|---:|
| Raw CSV（主にevents） | 約1.6百万行合計 | 0.6～1.2GB |
| Core BigQuery logical | 約1.7百万行合計 | 0.8～1.8GB |
| Core Parquet/Snappy | 同上 | 0.15～0.45GB |
| Intermediate＋Mart | 0.3～0.6百万行 | BigQuery 0.2～0.6GB、Parquet 0.05～0.2GB |
| dbt/temp/backupを1世代保持 | — | 0.5～1.5GB |

BigQueryでRaw、Staging、Core、Martをすべて永続化しても、基準ケースは概ね **3～6GB** と見込む。10GB無料枠に収まる可能性は高い。

## 7.2 BigQueryストレージの警告

以下の場合、10GBを超える可能性があるため**実行前相談を必須**とする。

- 生成データを基準ケースの2倍以上へ増やす
- Raw CSV外部保管とは別に、BigQuery RawとStagingの完全コピーを複数世代保持
- RFMを日次×全40,000顧客で2年分生成すると、最大約29.2百万行となり、現在案の月末snapshotより桁が増える
- イベントパラメータをGA4同様に大きなnested構造で重複保持
- Tableau用extractやバックアップをBigQuery内へ複製
- time travel／fail-safe、長期保存、streaming等の課金条件を無料枠と誤認

安全策：

- 生成後に`INFORMATION_SCHEMA.TABLE_STORAGE`で実測
- 中間tableへexpirationを設定
- RawはGCSへ保存し、BigQueryでは必要列のみ保持
- RFMは月末snapshot
- 8GB到達を内部警告、9GB到達を追加生成停止の目安とする

## 7.3 BigQueryクエリ量

概算例：

- events全表scan：0.8～1.5GB/query
- 30日partition scan：35～65MB/query
- 日次Martの1年scan：5～50MB/query

月間例：

| Workload | 回数 | 1回scan | 月間 |
|---|---:|---:|---:|
| ETL/dbt events増分 | 31 | 50MB | 約1.6GB |
| 月次full rebuild | 4 | 1.5GB | 約6GB |
| BI Mart query | 2,000 | 20MB | 約40GB |
| 開発・検証 | 200 | 200MB | 約40GB |
| 合計 | — | — | 約88GB/月 |

1TB/月に対して十分な余裕がある試算だが、Looker Studioが多数のchartごとにqueryを発行し、cacheが効かず、Core eventsへ直結すると増える。

警告例：

- events全scan 1.0GB × 1,000回 = 約1TB
- report 1閲覧あたり20 chart × 1GB × 50閲覧 = 約1TB

したがって、BIはMartへ接続し、Core eventsへ直接接続しない。すべての開発queryで可能な限りmaximum bytes billedを設定し、dry run後に実行する。**月次見込みが700GBを超えた時点で、追加公開・更新頻度・query設計を事前相談する**案を提案する。

無料枠の「10GB」「1TB」はユーザー提示条件を前提にしている。地域、課金モデル、BigQuery editions、free trial、料金改定をデプロイ時に公式料金ページで再確認する。

## 7.4 Athena scan料金

Parquet/Snappyの全Coreは概ね0.2～0.65GBと見込む。Athenaの一般的なオンデマンド料金を **5 USD/TB scanned** と仮定した参考値：

- 0.5GB full scan：約0.0025 USD
- 10GB scan：約0.05 USD
- 100GB scan：約0.50 USD
- 1TB scan：約5 USD

Athenaはqueryごとの最低課金scan量（一般に10MB単位として案内される）や丸めがあり得る。仮に2,000 query/月が各最低10MBなら約20GB、約0.10 USD相当である。

基準ケースではscan課金は小さい見込みだが、次は**事前相談を必須**とする。

- CSVのRawをBIへ直接接続
- partition filterなしの反復query
- CTAS／UNLOAD結果を同じprefixへ重複蓄積
- 100GB/月を超える見込み
- Tableau／外部BIが高頻度にAthenaをpolling
- Provisioned Capacity等、オンデマンドscan以外の契約を使う

料金はregion・最新価格で変わるため、実装時にAWS公式料金で再確認する。またAthena以外に次の少額費用が発生し得る。

- S3 storage、GET/LIST、data transfer
- Glue Data Catalog object/request
- Glue crawler／ETL job（利用する場合）
- CloudWatch logs/metrics
- Lambda
- NAT Gateway（特に無料志向では作成を避ける）

partition projectionを採用するため、定期crawlerは原則不要とする案を推奨する。

---

## 8. コストガードレール

### BigQuery

- BI専用Mart
- `require_partition_filter`
- dry run
- maximum bytes billed
- dataset/table expiration
- billing budget alert
- 日次でbytes billedを集計

### Athena

- Parquet/Snappy
- partition projection
- workgroup scan limit
- query result lifecycle
- S3 lifecycle
- `DataScannedInBytes`の集計

### 事前相談条件（提案）

次のいずれかに該当した場合、データ生成・公開更新・インフラ作成前にClaude Code側へ相談する。

1. BigQuery保存量見込み8GB以上
2. BigQuery月次query見込み700GB以上
3. Athena月次scan見込み100GB以上
4. 基準件数の2倍以上への拡大
5. 日次顧客snapshotなど、行数を1桁以上増やす設計変更
6. NAT Gateway、常時稼働compute、Glue crawler定期実行、Provisioned Capacityの追加
7. 無料枠の対象条件を公式資料で確認できない状態

---

## 9. 推奨実装順

1. 未決定7項目（売上、税送料、返金、帰属、RFM、小集団、期間）を確定
2. 共通schema定義をPython／YAML等の単一契約へ置き、両クラウドDDLとの差分テストを作る
3. 少量seed（ユーザー1,000、session 5,000）を生成
4. 金額、ID、event順序、funnelの品質テストを実行
5. Parquet schemaをGlue DDLと照合
6. BigQuery dry run／Athena scan bytesを実測
7. 基準ケースを生成
8. CoreとMartの合計一致を確認
9. Public用データを小集団抑制・匿名化
10. 実測容量・scan量がガードレール内であることを記録してからBIへ接続

本提案では、派手なデータ量よりも、同一seed・同一論理契約・同一品質テストでGCP/AWSの結果が一致することをポートフォリオ上の主要な評価材料とする。
