select
  o.order_id,
  o.recognized_revenue,
  sum(t.attributed_revenue_last_touch) as last_touch_revenue,
  sum(t.attributed_revenue_linear) as linear_revenue
from {{ ref('stg_fact_orders') }} o
left join {{ ref('int_order_touchpoints') }} t
  on o.order_id = t.order_id
group by o.order_id, o.recognized_revenue
having count(t.session_id) = 0
  or abs(o.recognized_revenue - sum(t.attributed_revenue_last_touch)) > 0.01
  or abs(o.recognized_revenue - sum(t.attributed_revenue_linear)) > 0.01
