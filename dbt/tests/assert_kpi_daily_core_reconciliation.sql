with core as (
  select
    order_date as metric_date,
    count(*) as orders,
    sum(recognized_revenue) as recognized_revenue
  from {{ ref('stg_fact_orders') }}
  where order_status = 'completed'
  group by order_date
),

mart as (
  select
    metric_date,
    sum(orders) as orders,
    sum(recognized_revenue) as recognized_revenue
  from {{ ref('mart_kpi_daily') }}
  group by metric_date
)

select
  coalesce(c.metric_date, m.metric_date) as metric_date,
  c.orders as core_orders,
  m.orders as mart_orders,
  c.recognized_revenue as core_revenue,
  m.recognized_revenue as mart_revenue
from core c
full outer join mart m
  on c.metric_date = m.metric_date
-- Compare values (coalescing absent sides to 0). Dates that exist only in the
-- mart (sessions but zero completed orders) are not a discrepancy; a genuine
-- order/revenue mismatch, or a completed-order date missing from the mart, is.
where coalesce(c.orders, 0) <> coalesce(m.orders, 0)
  or abs(coalesce(c.recognized_revenue, 0) - coalesce(m.recognized_revenue, 0))
    > 0.01
