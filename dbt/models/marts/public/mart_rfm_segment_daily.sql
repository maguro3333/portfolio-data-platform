select
  snapshot_date,
  rfm_segment,
  acquisition_source,
  membership_rank,
  count(*) as customers,
  sum(frequency_orders) as total_orders,
  {{ money_cast('sum(monetary_revenue)') }} as total_revenue,
  {{ money_cast('sum(monetary_gross_profit)') }} as total_gross_profit,
  {{ money_cast('avg(recency_days)') }} as avg_recency_days,
  {{ money_cast('avg(frequency_orders)') }} as avg_frequency_orders,
  {{ money_cast('avg(monetary_revenue)') }} as avg_monetary_revenue,
  {{ money_cast('avg(avg_order_value)') }} as avg_order_value
from {{ ref('mart_customer_rfm_snapshot') }}
group by
  snapshot_date,
  rfm_segment,
  acquisition_source,
  membership_rank
having count(*) >= {{ var('public_min_customers') }}
