with core as (
  select sum(recognized_revenue) as recognized_revenue
  from {{ ref('stg_fact_orders') }}
),

mart as (
  select
    sum(attributed_revenue_last_touch) as last_touch_revenue,
    sum(attributed_revenue_linear) as linear_revenue
  from {{ ref('mart_marketing_daily') }}
)

select *
from core
cross join mart
where abs(core.recognized_revenue - mart.last_touch_revenue) > 0.01
  or abs(core.recognized_revenue - mart.linear_revenue) > 0.01
