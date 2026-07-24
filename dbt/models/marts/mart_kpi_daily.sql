with session_metrics as (
  select
    session_date as metric_date,
    source,
    medium,
    device_category,
    customer_type,
    count(*) as sessions,
    sum(case when is_engaged_session then 1 else 0 end) as engaged_sessions
  from {{ ref('int_sessions_enriched') }}
  group by 1, 2, 3, 4, 5
),

-- Completed orders. Use a LEFT JOIN so orders without a matching session
-- (nullable session_id) are still counted and revenue reconciles to core.
order_metrics as (
  select
    o.order_date as metric_date,
    coalesce(s.source, '(direct)') as source,
    coalesce(s.medium, '(none)') as medium,
    coalesce(s.device_category, '(not set)') as device_category,
    coalesce(
      s.customer_type,
      case when o.is_first_order then 'new' else 'existing' end
    ) as customer_type,
    count(distinct o.session_id) as purchasing_sessions,
    count(*) as orders,
    count(distinct o.user_id) as purchasers,
    count(distinct case when o.is_first_order then o.user_id end)
      as new_customers,
    sum(o.gross_sales) as gross_sales,
    sum(o.discount_amount) as discount_amount,
    sum(o.recognized_revenue) as recognized_revenue,
    sum(o.cost_of_goods) as cost_of_goods,
    sum(o.gross_profit) as gross_profit
  from {{ ref('stg_fact_orders') }} o
  left join {{ ref('int_sessions_enriched') }} s
    on o.session_id = s.session_id
  where o.order_status = 'completed'
  group by 1, 2, 3, 4, 5
),

all_keys as (
  select metric_date, source, medium, device_category, customer_type
  from session_metrics
  union distinct
  select metric_date, source, medium, device_category, customer_type
  from order_metrics
)

select
  k.metric_date,
  k.source,
  k.medium,
  k.device_category,
  k.customer_type,
  coalesce(s.sessions, 0) as sessions,
  coalesce(s.engaged_sessions, 0) as engaged_sessions,
  coalesce(o.purchasing_sessions, 0) as purchasing_sessions,
  coalesce(o.orders, 0) as orders,
  coalesce(o.purchasers, 0) as purchasers,
  coalesce(o.new_customers, 0) as new_customers,
  {{ money_cast('coalesce(o.gross_sales, 0)') }} as gross_sales,
  {{ money_cast('coalesce(o.discount_amount, 0)') }}
    as discount_amount,
  {{ money_cast('coalesce(o.recognized_revenue, 0)') }}
    as recognized_revenue,
  {{ money_cast('coalesce(o.cost_of_goods, 0)') }} as cost_of_goods,
  {{ money_cast('coalesce(o.gross_profit, 0)') }} as gross_profit
from all_keys k
left join session_metrics s
  on k.metric_date = s.metric_date
  and k.source = s.source
  and k.medium = s.medium
  and k.device_category = s.device_category
  and k.customer_type = s.customer_type
left join order_metrics o
  on k.metric_date = o.metric_date
  and k.source = o.source
  and k.medium = o.medium
  and k.device_category = o.device_category
  and k.customer_type = o.customer_type
