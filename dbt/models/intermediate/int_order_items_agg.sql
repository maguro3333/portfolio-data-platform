select
  order_id,
  count(*) as order_line_count,
  sum(quantity) as item_quantity,
  sum(item_gross_sales) as item_gross_sales,
  sum(item_discount_amount) as item_discount_amount,
  sum(item_net_sales) as item_net_sales,
  sum(item_cost) as item_cost,
  sum(item_gross_profit) as item_gross_profit
from {{ ref('stg_fact_order_items') }}
group by order_id
