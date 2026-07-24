-- BigQuery Standard SQL
-- Replace PROJECT_ID and MART_DATASET before execution.
-- These are physical contracts for BI-facing materialized tables.

CREATE TABLE IF NOT EXISTS `PROJECT_ID.MART_DATASET.mart_kpi_daily` (
  metric_date DATE NOT NULL,
  source STRING NOT NULL,
  medium STRING NOT NULL,
  device_category STRING NOT NULL,
  customer_type STRING NOT NULL OPTIONS(description='new, existing, anonymous'),
  sessions INT64 NOT NULL,
  engaged_sessions INT64 NOT NULL,
  purchasing_sessions INT64 NOT NULL,
  orders INT64 NOT NULL,
  purchasers INT64 NOT NULL,
  new_customers INT64 NOT NULL,
  gross_sales NUMERIC NOT NULL,
  discount_amount NUMERIC NOT NULL,
  recognized_revenue NUMERIC NOT NULL,
  cost_of_goods NUMERIC NOT NULL,
  gross_profit NUMERIC NOT NULL
)
PARTITION BY metric_date
CLUSTER BY source, medium, device_category, customer_type
OPTIONS(require_partition_filter=TRUE, description='Daily executive KPI at explicit channel/device/customer-type grain.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.MART_DATASET.mart_marketing_daily` (
  metric_date DATE NOT NULL,
  source STRING NOT NULL,
  medium STRING NOT NULL,
  campaign_id STRING NOT NULL OPTIONS(description='Use (none) for unattributed traffic'),
  device_category STRING NOT NULL,
  sessions INT64 NOT NULL,
  engaged_sessions INT64 NOT NULL,
  view_item_sessions INT64 NOT NULL,
  add_to_cart_sessions INT64 NOT NULL,
  begin_checkout_sessions INT64 NOT NULL,
  purchasing_sessions INT64 NOT NULL,
  orders INT64 NOT NULL,
  new_customers INT64 NOT NULL,
  attributed_revenue_last_touch NUMERIC NOT NULL,
  attributed_revenue_linear NUMERIC NOT NULL,
  impressions INT64 NOT NULL,
  clicks INT64 NOT NULL,
  cost NUMERIC NOT NULL
)
PARTITION BY metric_date
CLUSTER BY campaign_id, source, medium, device_category
OPTIONS(require_partition_filter=TRUE, description='Daily marketing funnel and cost at campaign/device grain.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.MART_DATASET.mart_content_performance` (
  metric_date DATE NOT NULL,
  content_id STRING NOT NULL,
  content_type STRING NOT NULL,
  content_group STRING NOT NULL,
  content_view_sessions INT64 NOT NULL,
  content_view_users INT64 NOT NULL,
  engaged_sessions INT64 NOT NULL,
  engagement_time_msec INT64 NOT NULL,
  product_click_sessions INT64 NOT NULL,
  add_to_cart_sessions INT64 NOT NULL,
  direct_purchase_orders INT64 NOT NULL,
  direct_purchase_revenue NUMERIC NOT NULL
)
PARTITION BY metric_date
CLUSTER BY content_id, content_type, content_group
OPTIONS(require_partition_filter=TRUE, description='Daily content engagement and direct conversion metrics.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.MART_DATASET.mart_content_assists` (
  purchase_date DATE NOT NULL,
  content_id STRING NOT NULL,
  attribution_model STRING NOT NULL OPTIONS(description='last_touch or linear'),
  lookback_days INT64 NOT NULL,
  assisted_orders INT64 NOT NULL,
  assisted_purchasers INT64 NOT NULL,
  attributed_order_credit NUMERIC NOT NULL,
  attributed_revenue NUMERIC NOT NULL
)
PARTITION BY purchase_date
CLUSTER BY content_id, attribution_model
OPTIONS(require_partition_filter=TRUE, description='Content assist metrics at purchase date/content/model grain.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.MART_DATASET.mart_funnel_daily` (
  metric_date DATE NOT NULL,
  source STRING NOT NULL,
  medium STRING NOT NULL,
  device_category STRING NOT NULL,
  customer_type STRING NOT NULL,
  product_category_l1 STRING NOT NULL,
  funnel_step INT64 NOT NULL,
  funnel_event_name STRING NOT NULL,
  reached_sessions INT64 NOT NULL,
  previous_step_sessions INT64,
  step_conversion_rate NUMERIC,
  entry_conversion_rate NUMERIC
)
PARTITION BY metric_date
CLUSTER BY funnel_event_name, device_category, source, product_category_l1
OPTIONS(require_partition_filter=TRUE, description='Ordered four-step same-session funnel; NULL rate means no observable denominator.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.MART_DATASET.mart_customer_rfm_snapshot` (
  snapshot_date DATE NOT NULL,
  user_id STRING NOT NULL,
  first_order_date DATE NOT NULL,
  last_order_date DATE NOT NULL,
  recency_days INT64 NOT NULL,
  frequency_orders INT64 NOT NULL,
  monetary_revenue NUMERIC NOT NULL,
  monetary_gross_profit NUMERIC NOT NULL,
  avg_order_value NUMERIC NOT NULL,
  avg_days_between_orders NUMERIC,
  r_score INT64 NOT NULL,
  f_score INT64 NOT NULL,
  m_score INT64 NOT NULL,
  rfm_segment STRING NOT NULL,
  acquisition_source STRING NOT NULL,
  membership_rank STRING NOT NULL,
  created_at TIMESTAMP NOT NULL
)
PARTITION BY snapshot_date
CLUSTER BY rfm_segment, acquisition_source, membership_rank, user_id
OPTIONS(require_partition_filter=TRUE, description='Internal customer-level RFM monthly snapshot; do not publish.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.MART_DATASET.mart_rfm_segment_daily` (
  snapshot_date DATE NOT NULL,
  rfm_segment STRING NOT NULL,
  acquisition_source STRING NOT NULL,
  membership_rank STRING NOT NULL,
  customers INT64 NOT NULL,
  total_orders INT64 NOT NULL,
  total_revenue NUMERIC NOT NULL,
  total_gross_profit NUMERIC NOT NULL,
  avg_recency_days NUMERIC NOT NULL,
  avg_frequency_orders NUMERIC NOT NULL,
  avg_monetary_revenue NUMERIC NOT NULL,
  avg_order_value NUMERIC NOT NULL
)
PARTITION BY snapshot_date
CLUSTER BY rfm_segment, acquisition_source, membership_rank
OPTIONS(require_partition_filter=TRUE, description='Public-safe aggregated RFM snapshot; suppress groups below the agreed minimum count.');

CREATE TABLE IF NOT EXISTS `PROJECT_ID.MART_DATASET.mart_customer_cohort` (
  cohort_month DATE NOT NULL OPTIONS(description='First day of first-order month'),
  months_since_first INT64 NOT NULL,
  acquisition_source STRING NOT NULL,
  first_order_category_l1 STRING NOT NULL,
  cohort_customers INT64 NOT NULL,
  observable_customers INT64 NOT NULL,
  retained_customers INT64 OPTIONS(description='NULL when the period is not fully observable'),
  period_orders INT64,
  period_revenue NUMERIC,
  cumulative_orders INT64,
  cumulative_revenue NUMERIC,
  customer_retention_rate NUMERIC,
  cumulative_repeat_rate NUMERIC
)
PARTITION BY cohort_month
CLUSTER BY months_since_first, acquisition_source, first_order_category_l1
OPTIONS(description='Monthly first-purchase cohort. Unmatured period metrics remain NULL, never zero-filled.');
