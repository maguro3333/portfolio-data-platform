select *
from {{ ref('mart_customer_rfm_snapshot') }}
where first_order_date > snapshot_date
  or last_order_date > snapshot_date
  or recency_days < 0
