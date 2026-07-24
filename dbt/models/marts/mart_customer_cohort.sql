with completed_orders as (
  select *
  from {{ ref('stg_fact_orders') }}
  where order_status = 'completed'
),

ranked_orders as (
  select
    o.*,
    row_number() over (
      partition by user_id order by ordered_at, order_id
    ) as customer_order_number
  from completed_orders o
),

first_order_category as (
  select order_id, category_l1
  from (
    select
      i.order_id,
      p.category_l1,
      row_number() over (
        partition by i.order_id
        order by i.item_net_sales desc, i.order_item_id
      ) as category_rank
    from {{ ref('stg_fact_order_items') }} i
    inner join {{ ref('stg_dim_products') }} p
      on i.product_id = p.product_id
  ) ranked
  where category_rank = 1
),

customer_base as (
  select
    o.user_id,
    o.order_id as first_order_id,
    {{ month_start('o.order_date') }} as cohort_month,
    u.acquisition_source,
    c.category_l1 as first_order_category_l1
  from ranked_orders o
  inner join {{ ref('stg_dim_users') }} u
    on o.user_id = u.user_id
  inner join first_order_category c
    on o.order_id = c.order_id
  where o.customer_order_number = 1
),

months as (
  select distinct {{ month_start('calendar_date') }} as period_month
  from {{ ref('stg_dim_date') }}
),

cohort_sizes as (
  select
    cohort_month,
    acquisition_source,
    first_order_category_l1,
    count(*) as cohort_customers
  from customer_base
  group by cohort_month, acquisition_source, first_order_category_l1
),

cohort_grid as (
  select
    c.cohort_month,
    m.period_month,
    {{ month_diff('c.cohort_month', 'm.period_month') }} as months_since_first,
    c.acquisition_source,
    c.first_order_category_l1,
    c.cohort_customers,
    case
      when {{ month_end('m.period_month') }}
        <= cast('{{ var("data_end_date") }}' as date)
        then true else false
    end as is_observable
  from cohort_sizes c
  cross join months m
  where m.period_month >= c.cohort_month
),

customer_activity as (
  select
    b.user_id,
    b.cohort_month,
    b.acquisition_source,
    b.first_order_category_l1,
    {{ month_start('o.order_date') }} as period_month,
    count(*) as period_orders,
    sum(o.recognized_revenue) as period_revenue
  from customer_base b
  inner join completed_orders o
    on b.user_id = o.user_id
  group by
    b.user_id,
    b.cohort_month,
    b.acquisition_source,
    b.first_order_category_l1,
    {{ month_start('o.order_date') }}
),

first_repeat as (
  select
    b.user_id,
    min({{ month_start('o.order_date') }}) as first_repeat_month
  from customer_base b
  inner join ranked_orders o
    on b.user_id = o.user_id
  where o.customer_order_number > 1
  group by b.user_id
),

period_metrics as (
  select
    g.cohort_month,
    g.period_month,
    g.months_since_first,
    g.acquisition_source,
    g.first_order_category_l1,
    g.cohort_customers,
    g.is_observable,
    count(distinct a.user_id) as retained_customers,
    coalesce(sum(a.period_orders), 0) as period_orders,
    coalesce(sum(a.period_revenue), 0) as period_revenue
  from cohort_grid g
  left join customer_activity a
    on g.cohort_month = a.cohort_month
    and g.period_month = a.period_month
    and g.acquisition_source = a.acquisition_source
    and g.first_order_category_l1 = a.first_order_category_l1
  group by
    g.cohort_month,
    g.period_month,
    g.months_since_first,
    g.acquisition_source,
    g.first_order_category_l1,
    g.cohort_customers,
    g.is_observable
),

repeat_metrics as (
  select
    g.cohort_month,
    g.period_month,
    g.acquisition_source,
    g.first_order_category_l1,
    count(distinct case
      when r.first_repeat_month <= g.period_month then b.user_id
    end) as cumulative_repeat_customers
  from cohort_grid g
  inner join customer_base b
    on g.cohort_month = b.cohort_month
    and g.acquisition_source = b.acquisition_source
    and g.first_order_category_l1 = b.first_order_category_l1
  left join first_repeat r
    on b.user_id = r.user_id
  group by
    g.cohort_month,
    g.period_month,
    g.acquisition_source,
    g.first_order_category_l1
),

with_cumulative as (
  select
    p.*,
    sum(p.period_orders) over (
      partition by
        p.cohort_month,
        p.acquisition_source,
        p.first_order_category_l1
      order by p.months_since_first
      rows between unbounded preceding and current row
    ) as cumulative_orders,
    sum(p.period_revenue) over (
      partition by
        p.cohort_month,
        p.acquisition_source,
        p.first_order_category_l1
      order by p.months_since_first
      rows between unbounded preceding and current row
    ) as cumulative_revenue
  from period_metrics p
)

select
  p.cohort_month,
  p.months_since_first,
  p.acquisition_source,
  p.first_order_category_l1,
  p.cohort_customers,
  case when p.is_observable then p.cohort_customers end as observable_customers,
  case when p.is_observable then p.retained_customers end as retained_customers,
  case when p.is_observable then p.period_orders end as period_orders,
  {{ money_cast(
    'case when p.is_observable then p.period_revenue end'
  ) }} as period_revenue,
  case when p.is_observable then p.cumulative_orders end as cumulative_orders,
  {{ money_cast(
    'case when p.is_observable then p.cumulative_revenue end'
  ) }} as cumulative_revenue,
  case
    when p.is_observable
      then {{ safe_divide('p.retained_customers', 'p.cohort_customers') }}
  end as customer_retention_rate,
  case
    when p.is_observable
      then {{ safe_divide('r.cumulative_repeat_customers', 'p.cohort_customers') }}
  end as cumulative_repeat_rate
from with_cumulative p
inner join repeat_metrics r
  on p.cohort_month = r.cohort_month
  and p.period_month = r.period_month
  and p.acquisition_source = r.acquisition_source
  and p.first_order_category_l1 = r.first_order_category_l1
