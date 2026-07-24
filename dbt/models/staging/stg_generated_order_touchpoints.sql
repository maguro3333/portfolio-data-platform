select
  {{ string_cast('order_id') }} as order_id,
  cast(order_date as date) as order_date,
  {{ timestamp_cast('touchpoint_timestamp') }} as touchpoint_timestamp,
  {{ string_cast('session_id') }} as session_id,
  cast(touchpoint_sequence as bigint) as touchpoint_sequence,
  lower({{ string_cast('source') }}) as source,
  lower({{ string_cast('medium') }}) as medium,
  {{ nullable_string('campaign_id') }} as campaign_id,
  {{ nullable_string('content_id') }} as content_id,
  cast(days_before_purchase as bigint) as days_before_purchase,
  {{ bool_cast('is_first_touch') }} as is_first_touch,
  {{ bool_cast('is_last_touch') }} as is_last_touch,
  {{ rate_cast('last_touch_credit') }} as last_touch_credit,
  {{ rate_cast('linear_credit') }} as linear_credit,
  {{ money_cast('attributed_revenue_last_touch') }}
    as attributed_revenue_last_touch,
  {{ money_cast('attributed_revenue_linear') }}
    as attributed_revenue_linear,
  {{ timestamp_cast('created_at') }} as created_at
from {{ raw_relation('int_order_touchpoints') }}
