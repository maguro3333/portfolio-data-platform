with base as (
  select
    f.*,
    case
      when f.user_id is null then 'anonymous'
      when u.first_order_at is null or s.session_start_at <= u.first_order_at then 'new'
      else 'existing'
    end as customer_type
  from {{ ref('int_session_funnel') }} f
  inner join {{ ref('stg_fact_sessions') }} s
    on f.session_id = s.session_id
  left join {{ ref('stg_dim_users') }} u on u.user_id = f.user_id
),

aggregated as (
  select
    session_date as metric_date,
    source,
    medium,
    device_category,
    customer_type,
    product_category_l1,
    count(*) as entry_sessions,
    sum(case when reached_view_item then 1 else 0 end) as view_sessions,
    sum(case when reached_add_to_cart then 1 else 0 end) as cart_sessions,
    sum(case when reached_begin_checkout then 1 else 0 end) as checkout_sessions,
    sum(case when reached_purchase then 1 else 0 end) as purchase_sessions
  from base
  group by
    session_date,
    source,
    medium,
    device_category,
    customer_type,
    product_category_l1
),

steps as (
  select *, 1 as funnel_step, 'view_item' as funnel_event_name,
    view_sessions as reached_sessions, entry_sessions as previous_step_sessions
  from aggregated
  union all
  select *, 2, 'add_to_cart', cart_sessions, view_sessions from aggregated
  union all
  select *, 3, 'begin_checkout', checkout_sessions, cart_sessions from aggregated
  union all
  select *, 4, 'purchase', purchase_sessions, checkout_sessions from aggregated
)

select
  metric_date,
  source,
  medium,
  device_category,
  customer_type,
  product_category_l1,
  funnel_step,
  funnel_event_name,
  reached_sessions,
  previous_step_sessions,
  {{ safe_divide('reached_sessions', 'previous_step_sessions') }}
    as step_conversion_rate,
  {{ safe_divide('reached_sessions', 'entry_sessions') }}
    as entry_conversion_rate
from steps
