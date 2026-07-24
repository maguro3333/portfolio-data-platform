-- Aliases are prefixed so the HAVING clause's sum()/max() resolve to the base
-- columns (not the select aliases). BigQuery treats a same-named alias as an
-- aggregate and rejects sum(<alias>) as an aggregation-of-aggregation.
select
  order_id,
  sum(last_touch_credit) as sum_last_touch_credit,
  sum(linear_credit) as sum_linear_credit,
  max(days_before_purchase) as max_days_before_purchase
from {{ ref('int_order_touchpoints') }}
group by order_id
having abs(sum(last_touch_credit) - 1.000000) > 0.000001
  or abs(sum(linear_credit) - 1.000000) > 0.000001
  or max(days_before_purchase) > {{ var('attribution_lookback_days') }}
  or min(days_before_purchase) < 0
