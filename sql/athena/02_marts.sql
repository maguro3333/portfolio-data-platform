-- Athena engine v3 / AWS Glue Data Catalog DDL
-- Replace DATABASE_NAME and BUCKET_NAME/PREFIX before execution.
-- Files must be Parquet with Snappy compression and Hive-style date paths.

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.mart_kpi_daily (
  source STRING,
  medium STRING,
  device_category STRING,
  customer_type STRING,
  sessions BIGINT,
  engaged_sessions BIGINT,
  purchasing_sessions BIGINT,
  orders BIGINT,
  purchasers BIGINT,
  new_customers BIGINT,
  gross_sales DECIMAL(18,2),
  discount_amount DECIMAL(18,2),
  recognized_revenue DECIMAL(18,2),
  cost_of_goods DECIMAL(18,2),
  gross_profit DECIMAL(18,2)
)
PARTITIONED BY (metric_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/mart/mart_kpi_daily/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY', 'projection.enabled'='true',
  'projection.metric_date.type'='date', 'projection.metric_date.format'='yyyy-MM-dd',
  'projection.metric_date.range'='2024-01-01,NOW', 'projection.metric_date.interval'='1',
  'projection.metric_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/mart/mart_kpi_daily/metric_date=${metric_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.mart_marketing_daily (
  source STRING,
  medium STRING,
  campaign_id STRING,
  device_category STRING,
  sessions BIGINT,
  engaged_sessions BIGINT,
  view_item_sessions BIGINT,
  add_to_cart_sessions BIGINT,
  begin_checkout_sessions BIGINT,
  purchasing_sessions BIGINT,
  orders BIGINT,
  new_customers BIGINT,
  attributed_revenue_last_touch DECIMAL(18,2),
  attributed_revenue_linear DECIMAL(18,2),
  impressions BIGINT,
  clicks BIGINT,
  cost DECIMAL(18,2)
)
PARTITIONED BY (metric_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/mart/mart_marketing_daily/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY', 'projection.enabled'='true',
  'projection.metric_date.type'='date', 'projection.metric_date.format'='yyyy-MM-dd',
  'projection.metric_date.range'='2024-01-01,NOW', 'projection.metric_date.interval'='1',
  'projection.metric_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/mart/mart_marketing_daily/metric_date=${metric_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.mart_content_performance (
  content_id STRING,
  content_type STRING,
  content_group STRING,
  content_view_sessions BIGINT,
  content_view_users BIGINT,
  engaged_sessions BIGINT,
  engagement_time_msec BIGINT,
  product_click_sessions BIGINT,
  add_to_cart_sessions BIGINT,
  direct_purchase_orders BIGINT,
  direct_purchase_revenue DECIMAL(18,2)
)
PARTITIONED BY (metric_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/mart/mart_content_performance/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY', 'projection.enabled'='true',
  'projection.metric_date.type'='date', 'projection.metric_date.format'='yyyy-MM-dd',
  'projection.metric_date.range'='2024-01-01,NOW', 'projection.metric_date.interval'='1',
  'projection.metric_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/mart/mart_content_performance/metric_date=${metric_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.mart_content_assists (
  content_id STRING,
  attribution_model STRING,
  lookback_days BIGINT,
  assisted_orders BIGINT,
  assisted_purchasers BIGINT,
  attributed_order_credit DECIMAL(18,2),
  attributed_revenue DECIMAL(18,2)
)
PARTITIONED BY (purchase_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/mart/mart_content_assists/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY', 'projection.enabled'='true',
  'projection.purchase_date.type'='date', 'projection.purchase_date.format'='yyyy-MM-dd',
  'projection.purchase_date.range'='2024-01-01,NOW', 'projection.purchase_date.interval'='1',
  'projection.purchase_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/mart/mart_content_assists/purchase_date=${purchase_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.mart_funnel_daily (
  source STRING,
  medium STRING,
  device_category STRING,
  customer_type STRING,
  product_category_l1 STRING,
  funnel_step BIGINT,
  funnel_event_name STRING,
  reached_sessions BIGINT,
  previous_step_sessions BIGINT,
  step_conversion_rate DECIMAL(18,6),
  entry_conversion_rate DECIMAL(18,6)
)
PARTITIONED BY (metric_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/mart/mart_funnel_daily/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY', 'projection.enabled'='true',
  'projection.metric_date.type'='date', 'projection.metric_date.format'='yyyy-MM-dd',
  'projection.metric_date.range'='2024-01-01,NOW', 'projection.metric_date.interval'='1',
  'projection.metric_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/mart/mart_funnel_daily/metric_date=${metric_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.mart_customer_rfm_snapshot (
  user_id STRING,
  first_order_date DATE,
  last_order_date DATE,
  recency_days BIGINT,
  frequency_orders BIGINT,
  monetary_revenue DECIMAL(18,2),
  monetary_gross_profit DECIMAL(18,2),
  avg_order_value DECIMAL(18,2),
  avg_days_between_orders DECIMAL(18,2),
  r_score BIGINT,
  f_score BIGINT,
  m_score BIGINT,
  rfm_segment STRING,
  acquisition_source STRING,
  membership_rank STRING,
  created_at TIMESTAMP
)
PARTITIONED BY (snapshot_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/mart/mart_customer_rfm_snapshot/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY', 'projection.enabled'='true',
  'projection.snapshot_date.type'='date', 'projection.snapshot_date.format'='yyyy-MM-dd',
  'projection.snapshot_date.range'='2024-01-01,NOW', 'projection.snapshot_date.interval'='1',
  'projection.snapshot_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/mart/mart_customer_rfm_snapshot/snapshot_date=${snapshot_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.mart_rfm_segment_daily (
  rfm_segment STRING,
  acquisition_source STRING,
  membership_rank STRING,
  customers BIGINT,
  total_orders BIGINT,
  total_revenue DECIMAL(18,2),
  total_gross_profit DECIMAL(18,2),
  avg_recency_days DECIMAL(18,2),
  avg_frequency_orders DECIMAL(18,2),
  avg_monetary_revenue DECIMAL(18,2),
  avg_order_value DECIMAL(18,2)
)
PARTITIONED BY (snapshot_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/mart/mart_rfm_segment_daily/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY', 'projection.enabled'='true',
  'projection.snapshot_date.type'='date', 'projection.snapshot_date.format'='yyyy-MM-dd',
  'projection.snapshot_date.range'='2024-01-01,NOW', 'projection.snapshot_date.interval'='1',
  'projection.snapshot_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/mart/mart_rfm_segment_daily/snapshot_date=${snapshot_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.mart_customer_cohort (
  months_since_first BIGINT,
  acquisition_source STRING,
  first_order_category_l1 STRING,
  cohort_customers BIGINT,
  observable_customers BIGINT,
  retained_customers BIGINT,
  period_orders BIGINT,
  period_revenue DECIMAL(18,2),
  cumulative_orders BIGINT,
  cumulative_revenue DECIMAL(18,2),
  customer_retention_rate DECIMAL(18,6),
  cumulative_repeat_rate DECIMAL(18,6)
)
PARTITIONED BY (cohort_month DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/mart/mart_customer_cohort/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY', 'projection.enabled'='true',
  'projection.cohort_month.type'='date', 'projection.cohort_month.format'='yyyy-MM-dd',
  'projection.cohort_month.range'='2024-01-01,NOW', 'projection.cohort_month.interval'='1',
  'projection.cohort_month.interval.unit'='MONTHS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/mart/mart_customer_cohort/cohort_month=${cohort_month}/'
);
