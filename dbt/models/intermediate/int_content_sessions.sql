with content_exposure as (
  select
    session_id,
    content_id,
    min(event_timestamp) as first_content_view_at,
    sum(engagement_time_msec) as content_engagement_time_msec
  from {{ ref('stg_fact_events') }}
  where content_id is not null
  group by session_id, content_id
),

session_actions as (
  select
    session_id,
    max(case when event_name = 'view_item' then 1 else 0 end) as has_product_click,
    max(case when event_name = 'add_to_cart' then 1 else 0 end) as has_add_to_cart,
    count(distinct case when event_name = 'purchase' then order_id end)
      as direct_purchase_orders
  from {{ ref('stg_fact_events') }}
  group by session_id
),

session_revenue as (
  select
    session_id,
    sum(case when order_status = 'completed' then recognized_revenue else 0 end)
      as direct_purchase_revenue
  from {{ ref('stg_fact_orders') }}
  group by session_id
)

select
  s.session_date as metric_date,
  e.session_id,
  s.user_pseudo_id,
  e.content_id,
  s.is_engaged_session,
  e.content_engagement_time_msec,
  coalesce(a.has_product_click, 0) as has_product_click,
  coalesce(a.has_add_to_cart, 0) as has_add_to_cart,
  coalesce(a.direct_purchase_orders, 0) as direct_purchase_orders,
  coalesce(r.direct_purchase_revenue, 0) as direct_purchase_revenue
from content_exposure e
inner join {{ ref('stg_fact_sessions') }} s
  on e.session_id = s.session_id
left join session_actions a
  on e.session_id = a.session_id
left join session_revenue r
  on e.session_id = r.session_id
