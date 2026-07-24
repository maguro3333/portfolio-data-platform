with session_metrics as (
  select
    f.session_date as metric_date,
    f.source,
    f.medium,
    f.campaign_id,
    f.device_category,
    count(*) as sessions,
    sum(case when f.is_engaged_session then 1 else 0 end) as engaged_sessions,
    sum(case when f.reached_view_item then 1 else 0 end) as view_item_sessions,
    sum(case when f.reached_add_to_cart then 1 else 0 end)
      as add_to_cart_sessions,
    sum(case when f.reached_begin_checkout then 1 else 0 end)
      as begin_checkout_sessions,
    sum(case when f.reached_purchase then 1 else 0 end) as purchasing_sessions
  from {{ ref('int_session_funnel') }} f
  group by 1, 2, 3, 4, 5
),

order_metrics as (
  select
    o.order_date as metric_date,
    s.source,
    s.medium,
    coalesce(s.campaign_id, '(none)') as campaign_id,
    s.device_category,
    count(case when o.order_status = 'completed' then 1 end) as orders,
    count(distinct case
      when o.order_status = 'completed' and o.is_first_order then o.user_id
    end) as new_customers
  from {{ ref('stg_fact_orders') }} o
  inner join {{ ref('stg_fact_sessions') }} s
    on o.session_id = s.session_id
  group by 1, 2, 3, 4, 5
),

attribution_metrics as (
  select
    t.order_date as metric_date,
    t.source,
    t.medium,
    coalesce(t.campaign_id, '(none)') as campaign_id,
    s.device_category,
    sum(t.attributed_revenue_last_touch) as attributed_revenue_last_touch,
    sum(t.attributed_revenue_linear) as attributed_revenue_linear
  from {{ ref('int_order_touchpoints') }} t
  inner join {{ ref('stg_fact_sessions') }} s
    on t.session_id = s.session_id
  group by 1, 2, 3, 4, 5
),

-- Ad cost is only available at (date, source, medium, campaign) grain.
-- We do not have device-level cost, so cost is kept at campaign grain with
-- device_category = '(not set)'. This keeps cost reconciling exactly to the
-- source and avoids fabricating a device split.
cost_metrics as (
  select
    cost_date as metric_date,
    source,
    medium,
    campaign_id,
    '(not set)' as device_category,
    sum(impressions) as impressions,
    sum(clicks) as clicks,
    {{ money_cast('sum(cost)') }} as cost
  from {{ ref('stg_fact_campaign_cost_daily') }}
  group by 1, 2, 3, 4, 5
),

all_keys as (
  select metric_date, source, medium, campaign_id, device_category
  from session_metrics
  union distinct
  select metric_date, source, medium, campaign_id, device_category
  from order_metrics
  union distinct
  select metric_date, source, medium, campaign_id, device_category
  from attribution_metrics
  union distinct
  select metric_date, source, medium, campaign_id, device_category
  from cost_metrics
)

select
  k.metric_date,
  k.source,
  k.medium,
  k.campaign_id,
  k.device_category,
  coalesce(s.sessions, 0) as sessions,
  coalesce(s.engaged_sessions, 0) as engaged_sessions,
  coalesce(s.view_item_sessions, 0) as view_item_sessions,
  coalesce(s.add_to_cart_sessions, 0) as add_to_cart_sessions,
  coalesce(s.begin_checkout_sessions, 0) as begin_checkout_sessions,
  coalesce(s.purchasing_sessions, 0) as purchasing_sessions,
  coalesce(o.orders, 0) as orders,
  coalesce(o.new_customers, 0) as new_customers,
  {{ money_cast('coalesce(a.attributed_revenue_last_touch, 0)') }}
    as attributed_revenue_last_touch,
  {{ money_cast('coalesce(a.attributed_revenue_linear, 0)') }}
    as attributed_revenue_linear,
  coalesce(c.impressions, 0) as impressions,
  coalesce(c.clicks, 0) as clicks,
  {{ money_cast('coalesce(c.cost, 0)') }} as cost
from all_keys k
left join session_metrics s
  on k.metric_date = s.metric_date
  and k.source = s.source
  and k.medium = s.medium
  and k.campaign_id = s.campaign_id
  and k.device_category = s.device_category
left join order_metrics o
  on k.metric_date = o.metric_date
  and k.source = o.source
  and k.medium = o.medium
  and k.campaign_id = o.campaign_id
  and k.device_category = o.device_category
left join attribution_metrics a
  on k.metric_date = a.metric_date
  and k.source = a.source
  and k.medium = a.medium
  and k.campaign_id = a.campaign_id
  and k.device_category = a.device_category
left join cost_metrics c
  on k.metric_date = c.metric_date
  and k.source = c.source
  and k.medium = c.medium
  and k.campaign_id = c.campaign_id
  and k.device_category = c.device_category
