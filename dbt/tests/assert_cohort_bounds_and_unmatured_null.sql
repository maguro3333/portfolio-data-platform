select *
from {{ ref('mart_customer_cohort') }}
where retained_customers > cohort_customers
  or customer_retention_rate < 0
  or customer_retention_rate > 1
  or cumulative_repeat_rate < 0
  or cumulative_repeat_rate > 1
  or (
    observable_customers is null
    and (
      retained_customers is not null
      or period_orders is not null
      or period_revenue is not null
      or cumulative_orders is not null
      or cumulative_revenue is not null
      or customer_retention_rate is not null
      or cumulative_repeat_rate is not null
    )
  )
