select
  s.metric_date,
  s.content_id,
  c.content_type,
  c.content_group,
  count(*) as content_view_sessions,
  count(distinct s.user_pseudo_id) as content_view_users,
  sum(case when s.is_engaged_session then 1 else 0 end) as engaged_sessions,
  sum(s.content_engagement_time_msec) as engagement_time_msec,
  sum(s.has_product_click) as product_click_sessions,
  sum(s.has_add_to_cart) as add_to_cart_sessions,
  sum(s.direct_purchase_orders) as direct_purchase_orders,
  {{ money_cast('sum(s.direct_purchase_revenue)') }}
    as direct_purchase_revenue
from {{ ref('int_content_sessions') }} s
inner join {{ ref('stg_dim_content') }} c
  on s.content_id = c.content_id
group by
  s.metric_date,
  s.content_id,
  c.content_type,
  c.content_group
