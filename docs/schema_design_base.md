# スキーマ基本方針(Claude Code ドラフト / Phase1+2対象)

本書はClaude Codeが作成する基本方針。Codexはこれをレビューし、BigQuery DDL・Athena/Glue DDL・データ生成仕様(件数・分布・生成ロジック)へ詳細化すること。

対象スコープ: Phase1(全体KPI/マーケティング/コンテンツ) + Phase2(RFM・LTV/コホート/購買ファネル)。Phase3(クロスセル)は既存 `fact_order_items` のみで実現するため新規テーブル不要。Phase4(オムニチャネル)は対象外。

## レイヤー構成

1. **Raw/Staging**: 生成したCSVをそのまま取り込む層。型・重複・命名を整える以外の加工はしない
2. **Core**: ディメンショナルモデル(下記)
3. **Mart**: BIツールが直接参照する集計層(下記)

GCP(BigQuery)とAWS(Athena/Glue)で論理列名・粒度・指標定義を完全に一致させ、物理最適化(パーティション/クラスタ/ファイル形式)のみクラウドごとに最適化する。

## Core: ディメンション

| テーブル | 粒度 | 主要列(基本方針) |
|---|---|---|
| `dim_date` | 1日1行 | date_key, date, year, quarter, month, week, day_of_week, is_weekend, is_holiday, is_sale_period |
| `dim_users` | 1ユーザー1行(現在値) | user_sk, user_id, registration_at, registration_channel, acquisition_source/medium/campaign_id, country, region, prefecture, gender, age_band, membership_rank_current |
| `dim_membership_rank_history` | 会員×有効期間 | user_id, rank, valid_from, valid_to |
| `bridge_user_identity` | user_pseudo_id×user_id×有効期間 | 匿名行動ログとログイン会員を結びつける。1対1を仮定しない |
| `dim_products` | 1商品1行(現在値) | product_sk, product_id, product_name, brand, category_l1, category_l2, list_price, standard_cost, launch_date, is_active |
| `dim_campaign` | 1キャンペーン1行 | campaign_id, campaign_name, platform, source, medium, start_date, end_date |
| `dim_content` | 1コンテンツ1行 | content_id, title, content_type(blog/sns/lp), author, published_at, content_group, target_category |

方針: 商品・会員ランクのSCD Type2化はPhase1+2では見送り、`dim_membership_rank_history`のみ履歴化する(過去情報混入の防止が目的で最も効くため)。

## Core: ファクト

| テーブル | 粒度 | 主要列(基本方針) |
|---|---|---|
| `fact_orders` | 1注文1行 | order_id, user_id, ordered_at(パーティションキー), order_status, currency, gross_sales, discount_amount, tax_amount, shipping_amount, net_sales, coupon_code, is_first_order, device_category |
| `fact_order_items` | 1注文明細1行 | order_item_id, order_id, product_id, quantity, unit_list_price, unit_selling_price, unit_cost, item_gross_sales, item_discount_amount, item_net_sales |
| `fact_events` | 1イベント1行 | event_id, event_date(パーティションキー), event_timestamp, event_name, user_pseudo_id, user_id(nullable), session_id, page_location, page_path, content_id, content_group, product_id, source, medium, campaign_id, device_category, browser, os, country, region, engagement_time_msec, is_engaged_session, is_conversion_event |
| `fact_sessions` | 1セッション1行 | session_id, user_pseudo_id, session_start_at, session_end_at, landing_page, source, medium, campaign_id, device_category, is_converted_session, order_id(nullable) — `fact_events`全走査を避けるための集計テーブル |
| `fact_campaign_cost_daily` | 日×キャンペーン | cost_date(パーティションキー), campaign_id, platform, source, medium, impressions, clicks, cost, currency |

### ファネルイベント定義(基本方針)

`view_item` → `add_to_cart` → `begin_checkout` → `purchase` の4段階を必須とする(shipping/payment段階は任意拡張)。`event_id`で重複排除し、`session_id`+順序でファネル判定する。

### アトリビューション方針

`int_order_touchpoints`(中間モデル、1注文×1購入前タッチポイント)を用意し、`last_touch_credit`と`linear_credit`の2方式を持たせる。Looker Studio/Tableau側では帰属方式の切替ではなく、マート側で確定した値を参照する(BI側での複雑な計算は避ける)。

## Mart(BI直結層)

| マート | 粒度 | 対応ページ |
|---|---|---|
| `mart_kpi_daily` | 日×主要ディメンション | Page1 全体KPI |
| `mart_marketing_daily` | 日×チャネル×キャンペーン×デバイス | Page2 マーケティング |
| `mart_content_performance` | 日×コンテンツ | Page3 コンテンツ |
| `mart_content_assists` | コンテンツ×購入期間 | Page3 コンテンツ |
| `mart_funnel_daily` | 日×セグメント×ファネル段階 | Page6 ファネル |
| `mart_customer_rfm_snapshot` | 基準日×顧客 | Page4 RFM(非公開・内部用) |
| `mart_rfm_segment_daily` | 基準日×セグメント | Page4 RFM(Tableau Public公開用の集計版) |
| `mart_customer_cohort` | コホート月×経過月×属性 | Page5 コホート |

方針: 個人粒度の`mart_customer_rfm_snapshot`はTableau Publicには出さず、`mart_rfm_segment_daily`(セグメント集計)のみ公開する。

## データ品質方針(基本原則、Codexで具体テスト化)

- 主キーの一意性・NOT NULL制約
- `fact_orders`ヘッダー金額と`fact_order_items`合計の一致
- `purchase`イベントと`fact_orders`の照合率
- RFM計算は基準日以前のデータのみ使用(未来情報混入防止)
- コホートの未成熟セル(直近月)はNULL/未観測として扱い0埋めしない
- 広告費は日×キャンペーン粒度の`fact_campaign_cost_daily`をそのまま結合し、イベント/注文粒度に展開して多重計上しない

## Codexへの依頼事項

1. 上記方針をレビューし、不足・矛盾があれば指摘した上で、BigQuery DDL(パーティション/クラスタ設計含む)とAthena/Glue DDL(Parquet+パーティション設計含む)を作成
2. データ生成仕様のドラフト作成: 各テーブルの目標行数、ユーザー数・商品数・注文数・イベント数の関係性(1ユーザーあたり平均セッション数/イベント数など)、季節性・キャンペーン期間・カート放棄率など「それらしい」分布を持たせるための生成ロジック方針
3. 生成したデータ量がBigQuery無料枠(ストレージ10GB/月次クエリ1TB)・Athena想定コスト(スキャン量ベース)に収まることの概算試算
