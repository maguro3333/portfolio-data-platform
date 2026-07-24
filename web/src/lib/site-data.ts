export const projectFacts = [
  { term: "対象期間", detail: "2024-01-01〜2025-12-31（合成データ）" },
  { term: "データ規模", detail: "40,000 users / 220,000 sessions / 1,350,000 events / 10,800 orders" },
  { term: "クラウド", detail: "GCP: GCS + BigQuery / AWS: S3 + Glue + Athena" },
  { term: "変換", detail: "dbt Core、26 models、3 adapters" },
  { term: "検証", detail: "DuckDB / BigQuery / Athenaでdbt build 141 tests passed、KPI一致" },
  { term: "BI", detail: "Looker Studio / Tableau Public（埋め込みURL準備中）" },
] as const;

export const dataScale = [
  { value: "40,000", label: "users" },
  { value: "220,000", label: "sessions" },
  { value: "1,350,000", label: "events" },
  { value: "10,800", label: "orders" },
] as const;

export const navItems = [
  { href: "/", label: "Index" },
  { href: "/about", label: "About" },
  { href: "/architecture", label: "Architecture" },
  { href: "/data-pipeline", label: "Data & Pipeline" },
  { href: "/dashboards", label: "Dashboards" },
  { href: "/ai-analyst", label: "AI Analyst" },
] as const;

export const coreTables = [
  {
    name: "dim_date",
    kind: "Dimension",
    grain: "1日につき1行",
    keys: "date_key INTEGER",
    columns: "calendar_date DATE, year_month STRING, is_holiday BOOLEAN, season STRING, is_sale_period BOOLEAN",
    purpose: "日付属性、祝日、季節、セール期間",
  },
  {
    name: "dim_users",
    kind: "Dimension",
    grain: "登録会員につき1行",
    keys: "user_id STRING",
    columns: "registration_at TIMESTAMP, acquisition_source STRING, prefecture STRING, membership_rank_current STRING, first_order_at TIMESTAMP",
    purpose: "会員属性、獲得情報、初回購入",
  },
  {
    name: "dim_products",
    kind: "Dimension",
    grain: "商品につき1行",
    keys: "product_id STRING",
    columns: "product_name STRING, brand STRING, category_l1 STRING, list_price MONEY, standard_cost MONEY",
    purpose: "商品階層、定価、標準原価",
  },
  {
    name: "dim_campaign / dim_content",
    kind: "Dimension",
    grain: "campaignまたはcontentにつき1行",
    keys: "campaign_id / content_id STRING",
    columns: "source STRING, medium STRING, content_type STRING, published_at TIMESTAMP, content_group STRING",
    purpose: "広告施策とコンテンツの属性",
  },
  {
    name: "fact_orders",
    kind: "Fact",
    grain: "注文につき1行",
    keys: "order_id STRING",
    columns: "user_id STRING, session_id STRING, order_status STRING, item_net_sales MONEY, recognized_revenue MONEY, tax_amount MONEY, shipping_amount MONEY",
    purpose: "注文header、売上認識、税・送料、利益",
  },
  {
    name: "fact_order_items",
    kind: "Fact",
    grain: "注文明細につき1行",
    keys: "order_item_id STRING",
    columns: "order_id STRING, product_id STRING, quantity INTEGER, item_net_sales MONEY, item_cost MONEY, item_gross_profit MONEY",
    purpose: "商品別の数量、値引、売上、原価",
  },
  {
    name: "fact_sessions",
    kind: "Fact",
    grain: "セッションにつき1行",
    keys: "session_id STRING",
    columns: "user_pseudo_id STRING, user_id STRING, source STRING, medium STRING, device_category STRING, event_count INTEGER, session_revenue MONEY",
    purpose: "流入、端末、engagement、conversion",
  },
  {
    name: "fact_events",
    kind: "Fact",
    grain: "イベントにつき1行",
    keys: "event_id STRING",
    columns: "event_timestamp TIMESTAMP, event_name STRING, session_id STRING, event_sequence INTEGER, content_id STRING, product_id STRING, order_id STRING",
    purpose: "GA4 BigQuery Exportを参考にした行動ログ",
  },
  {
    name: "fact_campaign_cost_daily",
    kind: "Fact",
    grain: "日 × campaignにつき1行",
    keys: "cost_date DATE + campaign_id STRING",
    columns: "platform STRING, source STRING, medium STRING, impressions INTEGER, clicks INTEGER, cost MONEY",
    purpose: "広告費、impression、click",
  },
  {
    name: "bridge_user_identity / dim_membership_rank_history",
    kind: "Bridge / History",
    grain: "identity有効期間 / 会員ランク有効期間",
    keys: "user_pseudo_id + user_id + valid_from / user_id + valid_from",
    columns: "valid_from TIMESTAMP/DATE, valid_to TIMESTAMP/DATE, is_current BOOLEAN",
    purpose: "匿名IDと会員IDの接続、ランク履歴",
  },
] as const;

export const martDefinitions = [
  {
    name: "mart_kpi_daily",
    grain: "日 × source × medium × device × customer type",
    question: "売上、注文、購入者、粗利は日次でどう推移したか。",
    consumers: "全体KPI",
  },
  {
    name: "mart_marketing_daily",
    grain: "日 × source × medium × campaign × device",
    question: "チャネル別の流入、CV、広告費、帰属売上はどう異なるか。",
    consumers: "デジタルマーケティング",
  },
  {
    name: "mart_content_performance",
    grain: "日 × content",
    question: "各コンテンツの閲覧、engagement、直接購入はどう推移したか。",
    consumers: "コンテンツ制作",
  },
  {
    name: "mart_content_assists",
    grain: "購入日 × content × attribution model",
    question: "購入前接点として各コンテンツがどれだけ寄与したか。",
    consumers: "コンテンツ制作",
  },
  {
    name: "mart_funnel_daily",
    grain: "日 × segment × funnel step",
    question: "商品閲覧から購入まで、どの段階で離脱したか。",
    consumers: "購買ファネル",
  },
  {
    name: "mart_customer_rfm_snapshot",
    grain: "月末基準日 × customer",
    question: "顧客単位のrecency、frequency、monetaryと五分位scoreは何か。",
    consumers: "内部分析のみ",
  },
  {
    name: "mart_rfm_segment_daily",
    grain: "基準日 × RFM segment × 獲得属性",
    question: "顧客segmentの人数、売上、粗利はどう構成されるか。",
    consumers: "公開用CRM（customers >= 10）",
  },
  {
    name: "mart_customer_cohort",
    grain: "cohort month × 経過月 × 獲得属性",
    question: "獲得月別のretention、repeat、累積売上はどう推移したか。",
    consumers: "コホート・リテンション",
  },
] as const;

export type DashboardDefinition = {
  id: string;
  title: string;
  tool: string;
  status: string;
  description: string;
  marts: readonly string[];
  metrics: readonly string[];
};

export const dashboardItems: readonly DashboardDefinition[] = [
  {
    id: "kpi",
    title: "全体KPI",
    tool: "Looker Studio",
    status: "Embed URL pending",
    description: "日次の認識売上、注文、購入者、粗利を主要dimension別に確認する。",
    marts: ["mart_kpi_daily"],
    metrics: ["recognized_revenue", "orders", "purchasers", "AOV", "gross_profit"],
  },
  {
    id: "marketing",
    title: "デジタルマーケティング",
    tool: "Looker Studio",
    status: "Embed URL pending",
    description: "チャネル・campaign別に流入、CV、広告費、帰属売上を比較する。",
    marts: ["mart_marketing_daily"],
    metrics: ["sessions", "CVR", "CPA", "ROAS", "last non-direct / linear revenue"],
  },
  {
    id: "content",
    title: "コンテンツ制作",
    tool: "Looker Studio",
    status: "Embed URL pending",
    description: "コンテンツの直接CVと購入前接点としての寄与を分けて確認する。",
    marts: ["mart_content_performance", "mart_content_assists"],
    metrics: ["content view sessions", "engagement", "direct purchase", "assist credit"],
  },
  {
    id: "rfm",
    title: "RFM・LTV",
    tool: "Tableau Public",
    status: "Embed URL pending",
    description: "RFM五分位と顧客segmentの構成、売上、粗利を確認する。",
    marts: ["mart_rfm_segment_daily"],
    metrics: ["customers", "R/F/M score", "segment revenue", "avg order value"],
  },
  {
    id: "cohort",
    title: "コホート・リテンション",
    tool: "Tableau Public",
    status: "Embed URL pending",
    description: "初回購入月ごとの継続、repeat、累積売上を経過月で比較する。",
    marts: ["mart_customer_cohort"],
    metrics: ["retention rate", "repeat rate", "period revenue", "cumulative revenue"],
  },
  {
    id: "funnel",
    title: "購買ファネル",
    tool: "Tableau Public",
    status: "Embed URL pending",
    description: "商品閲覧からカート、checkout、購入までの到達と離脱を確認する。",
    marts: ["mart_funnel_daily"],
    metrics: ["100,100 view", "27,940 cart", "16,940 checkout", "10,500 purchase"],
  },
] as const;
