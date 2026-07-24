select *
from {{ ref('stg_fact_orders') }}
where (
    order_status = 'completed'
    and abs(recognized_revenue - item_net_sales) > 0.01
  )
  or (
    order_status in ('cancelled', 'refunded')
    and abs(recognized_revenue) > 0.01
  )
