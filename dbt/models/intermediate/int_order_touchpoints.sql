with eligible as (
  select
    o.order_id,
    o.order_date,
    o.ordered_at,
    o.recognized_revenue,
    s.session_id,
    s.session_start_at as touchpoint_timestamp,
    s.source,
    s.medium,
    s.campaign_id,
    s.landing_content_id as content_id,
    case
      when s.source = '(direct)' and s.medium = '(none)' then 1
      else 0
    end as is_direct
  from {{ ref('stg_fact_orders') }} o
  inner join {{ ref('stg_fact_sessions') }} s
    on o.user_id = s.user_id
    and s.session_start_at <= o.ordered_at
    and s.session_start_at >=
      {{ date_add_days('o.ordered_at', -var('attribution_lookback_days')) }}
),

ranked as (
  select
    *,
    row_number() over (
      partition by order_id
      order by touchpoint_timestamp, session_id
    ) as touchpoint_sequence,
    count(*) over (partition by order_id) as touchpoint_count,
    row_number() over (
      partition by order_id
      order by is_direct, touchpoint_timestamp desc, session_id desc
    ) as last_non_direct_rank
  from eligible
),

credited as (
  select
    *,
    case
      when touchpoint_sequence = touchpoint_count
        then {{ rate_cast('1.000000') }}
          - {{ rate_cast('round(1.000000 / touchpoint_count, 6)') }}
            * (touchpoint_count - 1)
      else {{ rate_cast('round(1.000000 / touchpoint_count, 6)') }}
    end as linear_credit,
    case when last_non_direct_rank = 1 then 1.000000 else 0.000000 end
      as last_touch_credit
  from ranked
)

select
  order_id,
  order_date,
  touchpoint_timestamp,
  session_id,
  touchpoint_sequence,
  source,
  medium,
  campaign_id,
  content_id,
  {{ day_diff('touchpoint_timestamp', 'ordered_at') }} as days_before_purchase,
  touchpoint_sequence = 1 as is_first_touch,
  touchpoint_sequence = touchpoint_count as is_last_touch,
  {{ rate_cast('last_touch_credit') }} as last_touch_credit,
  {{ rate_cast('linear_credit') }} as linear_credit,
  {{ money_cast(
    'case when last_non_direct_rank = 1 then recognized_revenue else 0 end'
  ) }} as attributed_revenue_last_touch,
  {{ money_cast(
    'case when touchpoint_sequence = touchpoint_count '
    ~ 'then recognized_revenue '
    ~ '- round(recognized_revenue / touchpoint_count, 2) '
    ~ '* (touchpoint_count - 1) '
    ~ 'else round(recognized_revenue / touchpoint_count, 2) end'
  ) }} as attributed_revenue_linear
from credited
