with pivoted as (
  select
    metric_date,
    source,
    medium,
    device_category,
    customer_type,
    product_category_l1,
    max(case when funnel_step = 1 then reached_sessions end) as viewed,
    max(case when funnel_step = 2 then reached_sessions end) as carted,
    max(case when funnel_step = 3 then reached_sessions end) as checkout,
    max(case when funnel_step = 4 then reached_sessions end) as purchased
  from {{ ref('mart_funnel_daily') }}
  group by
    metric_date,
    source,
    medium,
    device_category,
    customer_type,
    product_category_l1
)

select *
from pivoted
where purchased > checkout
  or checkout > carted
  or carted > viewed
