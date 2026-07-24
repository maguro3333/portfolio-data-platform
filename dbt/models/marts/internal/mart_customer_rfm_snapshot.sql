with snapshots as (
  select max(calendar_date) as snapshot_date
  from {{ ref('stg_dim_date') }}
  group by year_month
),

completed_orders as (
  select *
  from {{ ref('stg_fact_orders') }}
  where order_status = 'completed'
),

customer_values as (
  select
    s.snapshot_date,
    o.user_id,
    min(o.order_date) as first_order_date,
    max(o.order_date) as last_order_date,
    {{ day_diff('max(o.order_date)', 's.snapshot_date') }} as recency_days,
    count(*) as frequency_orders,
    sum(o.recognized_revenue) as monetary_revenue,
    sum(o.gross_profit) as monetary_gross_profit,
    avg(o.item_net_sales) as avg_order_value,
    case
      when count(*) > 1
        then {{ money_cast(
          day_diff('min(o.order_date)', 'max(o.order_date)')
        ) }} / (count(*) - 1)
    end as avg_days_between_orders
  from snapshots s
  inner join completed_orders o
    on o.order_date <= s.snapshot_date
  group by s.snapshot_date, o.user_id
),

scored as (
  select
    *,
    6 - ntile(5) over (
      partition by snapshot_date order by recency_days
    ) as r_score,
    ntile(5) over (
      partition by snapshot_date order by frequency_orders, user_id
    ) as f_score,
    ntile(5) over (
      partition by snapshot_date order by monetary_revenue, user_id
    ) as m_score
  from customer_values
),

segmented as (
  select
    *,
    case
      when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'champions'
      when r_score >= 3 and f_score >= 4 then 'loyal'
      when r_score >= 4 and f_score <= 2 then 'new_or_promising'
      when r_score <= 2 and f_score >= 3 then 'at_risk'
      when r_score = 1 and f_score <= 2 then 'hibernating'
      else 'needs_attention'
    end as rfm_segment
  from scored
)

select
  r.snapshot_date,
  r.user_id,
  r.first_order_date,
  r.last_order_date,
  r.recency_days,
  r.frequency_orders,
  {{ money_cast('r.monetary_revenue') }} as monetary_revenue,
  {{ money_cast('r.monetary_gross_profit') }} as monetary_gross_profit,
  {{ money_cast('r.avg_order_value') }} as avg_order_value,
  {{ money_cast('r.avg_days_between_orders') }} as avg_days_between_orders,
  r.r_score,
  r.f_score,
  r.m_score,
  r.rfm_segment,
  u.acquisition_source,
  coalesce(h.membership_rank, 'bronze') as membership_rank,
  cast('{{ var("data_end_date") }} 00:00:00' as timestamp) as created_at
from segmented r
inner join {{ ref('stg_dim_users') }} u
  on r.user_id = u.user_id
left join {{ ref('stg_dim_membership_rank_history') }} h
  on r.user_id = h.user_id
  and r.snapshot_date >= h.valid_from
  and (r.snapshot_date < h.valid_to or h.valid_to is null)
