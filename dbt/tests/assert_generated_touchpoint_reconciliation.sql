with generated as (
  select
    order_id,
    count(*) as touchpoints,
    sum(last_touch_credit) as last_credit,
    sum(linear_credit) as linear_credit
  from {{ ref('stg_generated_order_touchpoints') }}
  group by order_id
),

derived as (
  select
    order_id,
    count(*) as touchpoints,
    sum(last_touch_credit) as last_credit,
    sum(linear_credit) as linear_credit
  from {{ ref('int_order_touchpoints') }}
  group by order_id
)

select
  coalesce(g.order_id, d.order_id) as order_id,
  g.touchpoints as generated_touchpoints,
  d.touchpoints as derived_touchpoints
from generated g
full outer join derived d
  on g.order_id = d.order_id
where g.order_id is null
  or d.order_id is null
  or g.touchpoints <> d.touchpoints
  or abs(g.last_credit - d.last_credit) > 0.000001
  or abs(g.linear_credit - d.linear_credit) > 0.000001
