with purchase_events as (
  select order_id, count(*) as purchase_events
  from {{ ref('stg_fact_events') }}
  where event_name = 'purchase'
  group by order_id
)

select
  coalesce(o.order_id, e.order_id) as order_id,
  coalesce(e.purchase_events, 0) as purchase_events
from {{ ref('stg_fact_orders') }} o
full outer join purchase_events e
  on o.order_id = e.order_id
where o.order_id is null
  or e.order_id is null
  or e.purchase_events <> 1
