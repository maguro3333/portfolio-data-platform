with compared as (
  select
    *,
    lag(cumulative_orders) over (
      partition by cohort_month, acquisition_source, first_order_category_l1
      order by months_since_first
    ) as previous_orders,
    lag(cumulative_revenue) over (
      partition by cohort_month, acquisition_source, first_order_category_l1
      order by months_since_first
    ) as previous_revenue,
    lag(cumulative_repeat_rate) over (
      partition by cohort_month, acquisition_source, first_order_category_l1
      order by months_since_first
    ) as previous_repeat_rate
  from {{ ref('mart_customer_cohort') }}
)

select *
from compared
where cumulative_orders < previous_orders
  or cumulative_revenue < previous_revenue
  or cumulative_repeat_rate < previous_repeat_rate
