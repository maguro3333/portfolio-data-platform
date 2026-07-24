with models as (
  select
    order_date as purchase_date,
    content_id,
    'last_non_direct' as attribution_model,
    order_id,
    last_touch_credit as order_credit,
    attributed_revenue_last_touch as attributed_revenue
  from {{ ref('int_order_touchpoints') }}
  where content_id is not null
    and last_touch_credit > 0

  union all

  select
    order_date as purchase_date,
    content_id,
    'linear' as attribution_model,
    order_id,
    linear_credit as order_credit,
    attributed_revenue_linear as attributed_revenue
  from {{ ref('int_order_touchpoints') }}
  where content_id is not null
    and linear_credit > 0
)

select
  m.purchase_date,
  m.content_id,
  m.attribution_model,
  {{ var('attribution_lookback_days') }} as lookback_days,
  count(distinct m.order_id) as assisted_orders,
  count(distinct o.user_id) as assisted_purchasers,
  {{ rate_cast('sum(m.order_credit)') }} as attributed_order_credit,
  {{ money_cast('sum(m.attributed_revenue)') }} as attributed_revenue
from models m
inner join {{ ref('stg_fact_orders') }} o
  on m.order_id = o.order_id
group by
  m.purchase_date,
  m.content_id,
  m.attribution_model
