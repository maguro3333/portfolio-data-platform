-- Athena engine v3 / AWS Glue Data Catalog DDL
-- Replace DATABASE_NAME and BUCKET_NAME/PREFIX before execution.
-- Files must be Parquet (recommended compression: Snappy).
-- Partitioned paths use Hive style: <table>/<partition_column>=YYYY-MM-DD/

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.dim_date (
  date_key BIGINT,
  calendar_date DATE,
  calendar_year BIGINT,
  calendar_quarter BIGINT,
  calendar_month BIGINT,
  year_month STRING,
  iso_week BIGINT,
  day_of_month BIGINT,
  day_of_week BIGINT,
  day_name STRING,
  is_weekend BOOLEAN,
  is_holiday BOOLEAN,
  holiday_name STRING,
  season STRING,
  is_sale_period BOOLEAN,
  sale_period_name STRING
)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/dim_date/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.dim_users (
  user_sk BIGINT,
  user_id STRING,
  registration_at TIMESTAMP,
  registration_channel STRING,
  acquisition_source STRING,
  acquisition_medium STRING,
  acquisition_campaign_id STRING,
  country STRING,
  region STRING,
  prefecture STRING,
  gender STRING,
  age_band STRING,
  membership_rank_current STRING,
  first_order_at TIMESTAMP,
  first_order_id STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/dim_users/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.dim_membership_rank_history (
  user_id STRING,
  membership_rank STRING,
  valid_to DATE,
  is_current BOOLEAN,
  created_at TIMESTAMP
)
PARTITIONED BY (valid_from DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/dim_membership_rank_history/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY',
  'projection.enabled'='true',
  'projection.valid_from.type'='date',
  'projection.valid_from.format'='yyyy-MM-dd',
  'projection.valid_from.range'='2024-01-01,NOW',
  'projection.valid_from.interval'='1',
  'projection.valid_from.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/core/dim_membership_rank_history/valid_from=${valid_from}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.bridge_user_identity (
  user_pseudo_id STRING,
  user_id STRING,
  valid_from TIMESTAMP,
  valid_to TIMESTAMP,
  identity_source STRING,
  is_current BOOLEAN,
  created_at TIMESTAMP
)
PARTITIONED BY (valid_from_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/bridge_user_identity/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY',
  'projection.enabled'='true',
  'projection.valid_from_date.type'='date',
  'projection.valid_from_date.format'='yyyy-MM-dd',
  'projection.valid_from_date.range'='2024-01-01,NOW',
  'projection.valid_from_date.interval'='1',
  'projection.valid_from_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/core/bridge_user_identity/valid_from_date=${valid_from_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.dim_products (
  product_sk BIGINT,
  product_id STRING,
  product_name STRING,
  brand STRING,
  category_l1 STRING,
  category_l2 STRING,
  list_price DECIMAL(18,2),
  standard_cost DECIMAL(18,2),
  launch_date DATE,
  is_active BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/dim_products/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.dim_campaign (
  campaign_id STRING,
  campaign_name STRING,
  platform STRING,
  source STRING,
  medium STRING,
  campaign_type STRING,
  start_date DATE,
  end_date DATE,
  is_paid BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/dim_campaign/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.dim_content (
  content_id STRING,
  title STRING,
  content_type STRING,
  author STRING,
  published_at TIMESTAMP,
  content_group STRING,
  target_category STRING,
  page_path STRING,
  is_active BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/dim_content/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.fact_orders (
  order_id STRING,
  user_id STRING,
  session_id STRING,
  ordered_at TIMESTAMP,
  order_status STRING,
  currency STRING,
  gross_sales DECIMAL(18,2),
  discount_amount DECIMAL(18,2),
  item_net_sales DECIMAL(18,2),
  tax_amount DECIMAL(18,2),
  shipping_amount DECIMAL(18,2),
  order_total DECIMAL(18,2),
  recognized_revenue DECIMAL(18,2),
  cost_of_goods DECIMAL(18,2),
  gross_profit DECIMAL(18,2),
  coupon_code STRING,
  is_first_order BOOLEAN,
  device_category STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
PARTITIONED BY (order_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/fact_orders/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY',
  'projection.enabled'='true',
  'projection.order_date.type'='date',
  'projection.order_date.format'='yyyy-MM-dd',
  'projection.order_date.range'='2024-01-01,NOW',
  'projection.order_date.interval'='1',
  'projection.order_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/core/fact_orders/order_date=${order_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.fact_order_items (
  order_item_id STRING,
  order_id STRING,
  product_id STRING,
  quantity BIGINT,
  unit_list_price DECIMAL(18,2),
  unit_selling_price DECIMAL(18,2),
  unit_cost DECIMAL(18,2),
  item_gross_sales DECIMAL(18,2),
  item_discount_amount DECIMAL(18,2),
  item_net_sales DECIMAL(18,2),
  item_cost DECIMAL(18,2),
  item_gross_profit DECIMAL(18,2),
  created_at TIMESTAMP
)
PARTITIONED BY (order_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/fact_order_items/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY',
  'projection.enabled'='true',
  'projection.order_date.type'='date',
  'projection.order_date.format'='yyyy-MM-dd',
  'projection.order_date.range'='2024-01-01,NOW',
  'projection.order_date.interval'='1',
  'projection.order_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/core/fact_order_items/order_date=${order_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.fact_events (
  event_id STRING,
  event_timestamp TIMESTAMP,
  event_name STRING,
  user_pseudo_id STRING,
  user_id STRING,
  session_id STRING,
  event_sequence BIGINT,
  page_location STRING,
  page_path STRING,
  page_title STRING,
  content_id STRING,
  content_group STRING,
  product_id STRING,
  order_id STRING,
  source STRING,
  medium STRING,
  campaign_id STRING,
  device_category STRING,
  browser STRING,
  operating_system STRING,
  country STRING,
  region STRING,
  engagement_time_msec BIGINT,
  is_engaged_session BOOLEAN,
  is_conversion_event BOOLEAN,
  created_at TIMESTAMP
)
PARTITIONED BY (event_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/fact_events/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY',
  'projection.enabled'='true',
  'projection.event_date.type'='date',
  'projection.event_date.format'='yyyy-MM-dd',
  'projection.event_date.range'='2024-01-01,NOW',
  'projection.event_date.interval'='1',
  'projection.event_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/core/fact_events/event_date=${event_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.fact_sessions (
  session_id STRING,
  user_pseudo_id STRING,
  user_id STRING,
  session_start_at TIMESTAMP,
  session_end_at TIMESTAMP,
  landing_page STRING,
  landing_content_id STRING,
  source STRING,
  medium STRING,
  campaign_id STRING,
  device_category STRING,
  browser STRING,
  operating_system STRING,
  country STRING,
  region STRING,
  event_count BIGINT,
  engagement_time_msec BIGINT,
  is_engaged_session BOOLEAN,
  is_converted_session BOOLEAN,
  order_count BIGINT,
  session_revenue DECIMAL(18,2),
  created_at TIMESTAMP
)
PARTITIONED BY (session_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/fact_sessions/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY',
  'projection.enabled'='true',
  'projection.session_date.type'='date',
  'projection.session_date.format'='yyyy-MM-dd',
  'projection.session_date.range'='2024-01-01,NOW',
  'projection.session_date.interval'='1',
  'projection.session_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/core/fact_sessions/session_date=${session_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.fact_campaign_cost_daily (
  campaign_id STRING,
  platform STRING,
  source STRING,
  medium STRING,
  impressions BIGINT,
  clicks BIGINT,
  cost DECIMAL(18,2),
  currency STRING,
  created_at TIMESTAMP
)
PARTITIONED BY (cost_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/fact_campaign_cost_daily/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY',
  'projection.enabled'='true',
  'projection.cost_date.type'='date',
  'projection.cost_date.format'='yyyy-MM-dd',
  'projection.cost_date.range'='2024-01-01,NOW',
  'projection.cost_date.interval'='1',
  'projection.cost_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/core/fact_campaign_cost_daily/cost_date=${cost_date}/'
);

CREATE EXTERNAL TABLE IF NOT EXISTS DATABASE_NAME.int_order_touchpoints (
  order_id STRING,
  touchpoint_timestamp TIMESTAMP,
  session_id STRING,
  touchpoint_sequence BIGINT,
  source STRING,
  medium STRING,
  campaign_id STRING,
  content_id STRING,
  days_before_purchase BIGINT,
  is_first_touch BOOLEAN,
  is_last_touch BOOLEAN,
  last_touch_credit DECIMAL(18,2),
  linear_credit DECIMAL(18,2),
  attributed_revenue_last_touch DECIMAL(18,2),
  attributed_revenue_linear DECIMAL(18,2),
  created_at TIMESTAMP
)
PARTITIONED BY (order_date DATE)
STORED AS PARQUET
LOCATION 's3://BUCKET_NAME/PREFIX/core/int_order_touchpoints/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY',
  'projection.enabled'='true',
  'projection.order_date.type'='date',
  'projection.order_date.format'='yyyy-MM-dd',
  'projection.order_date.range'='2024-01-01,NOW',
  'projection.order_date.interval'='1',
  'projection.order_date.interval.unit'='DAYS',
  'storage.location.template'='s3://BUCKET_NAME/PREFIX/core/int_order_touchpoints/order_date=${order_date}/'
);
