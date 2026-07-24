select *
from {{ ref('stg_fact_order_items') }}
where abs(item_gross_sales - quantity * unit_list_price) > 0.01
  or abs(item_discount_amount - (item_gross_sales - item_net_sales)) > 0.01
  or abs(item_cost - quantity * unit_cost) > 0.01
  or abs(item_gross_profit - (item_net_sales - item_cost)) > 0.01
