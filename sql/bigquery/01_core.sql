-- BigQuery Standard SQL
-- Replace PROJECT_ID and CORE_DATASET before execution.
-- Logical types map to Athena as follows:
-- STRING=STRING, INT64=BIGINT, NUMERIC=DECIMAL(18,2),
-- DATE=DATE, TIMESTAMP=TIMESTAMP, BOOL=BOOLEAN.

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.dim_date` (
  date_key INT64 NOT NULL OPTIONS(description='YYYYMMDD'),
  calendar_date DATE NOT NULL,
  calendar_year INT64 NOT NULL,
  calendar_quarter INT64 NOT NULL,
  calendar_month INT64 NOT NULL,
  year_month STRING NOT NULL,
  iso_week INT64 NOT NULL,
  day_of_month INT64 NOT NULL,
  day_of_week INT64 NOT NULL OPTIONS(description='ISO: Monday=1, Sunday=7'),
  day_name STRING NOT NULL,
  is_weekend BOOL NOT NULL,
  is_holiday BOOL NOT NULL,
  holiday_name STRING,
  season STRING NOT NULL,
  is_sale_period BOOL NOT NULL,
  sale_period_name STRING,
  CONSTRAINT pk_dim_date PRIMARY KEY (date_key) NOT ENFORCED
)
OPTIONS(description='One row per calendar date; common calendar and sale flags.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.dim_users` (
  user_sk INT64 NOT NULL,
  user_id STRING NOT NULL,
  registration_at TIMESTAMP NOT NULL,
  registration_channel STRING NOT NULL,
  acquisition_source STRING NOT NULL,
  acquisition_medium STRING NOT NULL,
  acquisition_campaign_id STRING,
  country STRING NOT NULL,
  region STRING NOT NULL,
  prefecture STRING,
  gender STRING OPTIONS(description='female, male, non_binary, unknown'),
  age_band STRING OPTIONS(description='18-24, 25-34, 35-44, 45-54, 55-64, 65+, unknown'),
  membership_rank_current STRING NOT NULL,
  first_order_at TIMESTAMP,
  first_order_id STRING,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_dim_users PRIMARY KEY (user_id) NOT ENFORCED
)
CLUSTER BY acquisition_source, membership_rank_current, region
OPTIONS(description='Current-state registered customer dimension; contains no direct PII.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.dim_membership_rank_history` (
  user_id STRING NOT NULL,
  membership_rank STRING NOT NULL,
  valid_from DATE NOT NULL,
  valid_to DATE,
  is_current BOOL NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_rank_history PRIMARY KEY (user_id, valid_from) NOT ENFORCED
)
PARTITION BY DATE_TRUNC(valid_from, MONTH)
CLUSTER BY user_id, membership_rank
OPTIONS(
  require_partition_filter=TRUE,
  description='One row per user and non-overlapping membership-rank validity period; valid_to is exclusive.'
);

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.bridge_user_identity` (
  user_pseudo_id STRING NOT NULL,
  user_id STRING NOT NULL,
  valid_from TIMESTAMP NOT NULL,
  valid_to TIMESTAMP,
  identity_source STRING NOT NULL OPTIONS(description='login, registration, deterministic_backfill'),
  is_current BOOL NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_identity_bridge PRIMARY KEY (user_pseudo_id, user_id, valid_from) NOT ENFORCED
)
PARTITION BY DATE(valid_from)
CLUSTER BY user_pseudo_id, user_id
OPTIONS(
  require_partition_filter=TRUE,
  description='Many-to-many capable anonymous-to-member identity bridge; valid_to is exclusive.'
);

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.dim_products` (
  product_sk INT64 NOT NULL,
  product_id STRING NOT NULL,
  product_name STRING NOT NULL,
  brand STRING NOT NULL,
  category_l1 STRING NOT NULL,
  category_l2 STRING NOT NULL,
  list_price NUMERIC NOT NULL,
  standard_cost NUMERIC NOT NULL,
  launch_date DATE NOT NULL,
  is_active BOOL NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_dim_products PRIMARY KEY (product_id) NOT ENFORCED
)
CLUSTER BY category_l1, category_l2, brand
OPTIONS(description='Current-state product dimension; price history is outside Phase 1+2.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.dim_campaign` (
  campaign_id STRING NOT NULL,
  campaign_name STRING NOT NULL,
  platform STRING NOT NULL,
  source STRING NOT NULL,
  medium STRING NOT NULL,
  campaign_type STRING NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_paid BOOL NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_dim_campaign PRIMARY KEY (campaign_id) NOT ENFORCED
)
CLUSTER BY platform, source, medium
OPTIONS(description='Campaign master; campaign_id is the stable join key.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.dim_content` (
  content_id STRING NOT NULL,
  title STRING NOT NULL,
  content_type STRING NOT NULL OPTIONS(description='blog, sns, lp'),
  author STRING NOT NULL,
  published_at TIMESTAMP NOT NULL,
  content_group STRING NOT NULL,
  target_category STRING,
  page_path STRING,
  is_active BOOL NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_dim_content PRIMARY KEY (content_id) NOT ENFORCED
)
CLUSTER BY content_type, content_group, target_category
OPTIONS(description='Content master used for content performance and assists.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.fact_orders` (
  order_id STRING NOT NULL,
  user_id STRING NOT NULL,
  session_id STRING,
  ordered_at TIMESTAMP NOT NULL,
  order_date DATE NOT NULL,
  order_status STRING NOT NULL OPTIONS(description='completed, cancelled, refunded'),
  currency STRING NOT NULL,
  gross_sales NUMERIC NOT NULL OPTIONS(description='Items at list price before item discounts; excludes tax and shipping'),
  discount_amount NUMERIC NOT NULL,
  item_net_sales NUMERIC NOT NULL OPTIONS(description='gross_sales - discount_amount'),
  tax_amount NUMERIC NOT NULL,
  shipping_amount NUMERIC NOT NULL,
  order_total NUMERIC NOT NULL OPTIONS(description='item_net_sales + tax_amount + shipping_amount'),
  recognized_revenue NUMERIC NOT NULL OPTIONS(description='Revenue after cancellation/refund adjustment; definition fixed in semantic contract'),
  cost_of_goods NUMERIC NOT NULL,
  gross_profit NUMERIC NOT NULL OPTIONS(description='recognized_revenue - cost_of_goods; excludes marketing and fulfillment cost'),
  coupon_code STRING,
  is_first_order BOOL NOT NULL,
  device_category STRING NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_fact_orders PRIMARY KEY (order_id) NOT ENFORCED
)
PARTITION BY order_date
CLUSTER BY user_id, order_status, session_id, device_category
OPTIONS(
  require_partition_filter=TRUE,
  description='One row per order. session_id is nullable; multiple orders per session are allowed.'
);

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.fact_order_items` (
  order_item_id STRING NOT NULL,
  order_id STRING NOT NULL,
  order_date DATE NOT NULL,
  product_id STRING NOT NULL,
  quantity INT64 NOT NULL,
  unit_list_price NUMERIC NOT NULL,
  unit_selling_price NUMERIC NOT NULL,
  unit_cost NUMERIC NOT NULL,
  item_gross_sales NUMERIC NOT NULL,
  item_discount_amount NUMERIC NOT NULL,
  item_net_sales NUMERIC NOT NULL,
  item_cost NUMERIC NOT NULL,
  item_gross_profit NUMERIC NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_fact_order_items PRIMARY KEY (order_item_id) NOT ENFORCED
)
PARTITION BY order_date
CLUSTER BY order_id, product_id
OPTIONS(
  require_partition_filter=TRUE,
  description='One row per order line; order_date is denormalized for partition pruning.'
);

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.fact_events` (
  event_id STRING NOT NULL,
  event_date DATE NOT NULL,
  event_timestamp TIMESTAMP NOT NULL,
  event_name STRING NOT NULL,
  user_pseudo_id STRING NOT NULL,
  user_id STRING,
  session_id STRING NOT NULL,
  event_sequence INT64 NOT NULL OPTIONS(description='Monotonic sequence within session after deduplication'),
  page_location STRING,
  page_path STRING,
  page_title STRING,
  content_id STRING,
  content_group STRING,
  product_id STRING,
  order_id STRING,
  source STRING NOT NULL,
  medium STRING NOT NULL,
  campaign_id STRING,
  device_category STRING NOT NULL,
  browser STRING NOT NULL,
  operating_system STRING NOT NULL,
  country STRING NOT NULL,
  region STRING NOT NULL,
  engagement_time_msec INT64 NOT NULL,
  is_engaged_session BOOL NOT NULL,
  is_conversion_event BOOL NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_fact_events PRIMARY KEY (event_id) NOT ENFORCED
)
PARTITION BY event_date
CLUSTER BY event_name, session_id, user_pseudo_id, campaign_id
OPTIONS(
  require_partition_filter=TRUE,
  description='Flattened GA4-like event fact; event_date uses the project reporting timezone.'
);

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.fact_sessions` (
  session_id STRING NOT NULL,
  session_date DATE NOT NULL,
  user_pseudo_id STRING NOT NULL,
  user_id STRING,
  session_start_at TIMESTAMP NOT NULL,
  session_end_at TIMESTAMP NOT NULL,
  landing_page STRING NOT NULL,
  landing_content_id STRING,
  source STRING NOT NULL,
  medium STRING NOT NULL,
  campaign_id STRING,
  device_category STRING NOT NULL,
  browser STRING NOT NULL,
  operating_system STRING NOT NULL,
  country STRING NOT NULL,
  region STRING NOT NULL,
  event_count INT64 NOT NULL,
  engagement_time_msec INT64 NOT NULL,
  is_engaged_session BOOL NOT NULL,
  is_converted_session BOOL NOT NULL,
  order_count INT64 NOT NULL,
  session_revenue NUMERIC NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_fact_sessions PRIMARY KEY (session_id) NOT ENFORCED
)
PARTITION BY session_date
CLUSTER BY source, medium, campaign_id, device_category
OPTIONS(
  require_partition_filter=TRUE,
  description='One row per session. order_count supports zero, one, or multiple matched orders.'
);

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.fact_campaign_cost_daily` (
  cost_date DATE NOT NULL,
  campaign_id STRING NOT NULL,
  platform STRING NOT NULL,
  source STRING NOT NULL,
  medium STRING NOT NULL,
  impressions INT64 NOT NULL,
  clicks INT64 NOT NULL,
  cost NUMERIC NOT NULL,
  currency STRING NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_campaign_cost PRIMARY KEY (cost_date, campaign_id) NOT ENFORCED
)
PARTITION BY cost_date
CLUSTER BY campaign_id, platform, source, medium
OPTIONS(
  require_partition_filter=TRUE,
  description='One row per date and campaign; never join directly to event or order grain.'
);

CREATE TABLE IF NOT EXISTS `PROJECT_ID.CORE_DATASET.int_order_touchpoints` (
  order_id STRING NOT NULL,
  order_date DATE NOT NULL,
  touchpoint_timestamp TIMESTAMP NOT NULL,
  session_id STRING NOT NULL,
  touchpoint_sequence INT64 NOT NULL,
  source STRING NOT NULL,
  medium STRING NOT NULL,
  campaign_id STRING,
  content_id STRING,
  days_before_purchase INT64 NOT NULL,
  is_first_touch BOOL NOT NULL,
  is_last_touch BOOL NOT NULL,
  last_touch_credit NUMERIC NOT NULL OPTIONS(description='Credits per order sum to 1.00'),
  linear_credit NUMERIC NOT NULL OPTIONS(description='Credits per order sum to 1.00'),
  attributed_revenue_last_touch NUMERIC NOT NULL,
  attributed_revenue_linear NUMERIC NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT pk_order_touchpoints PRIMARY KEY (order_id, touchpoint_sequence) NOT ENFORCED
)
PARTITION BY order_date
CLUSTER BY order_id, campaign_id, content_id, session_id
OPTIONS(
  require_partition_filter=TRUE,
  description='One row per order and eligible pre-purchase session touchpoint within a fixed lookback window.'
);
