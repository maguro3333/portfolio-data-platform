select
  {{ string_cast('order_item_id') }} as order_item_id,
  {{ string_cast('order_id') }} as order_id,
  cast(order_date as date) as order_date,
  {{ string_cast('product_id') }} as product_id,
  cast(quantity as bigint) as quantity,
  {{ money_cast('unit_list_price') }} as unit_list_price,
  {{ money_cast('unit_selling_price') }} as unit_selling_price,
  {{ money_cast('unit_cost') }} as unit_cost,
  {{ money_cast('item_gross_sales') }} as item_gross_sales,
  {{ money_cast('item_discount_amount') }} as item_discount_amount,
  {{ money_cast('item_net_sales') }} as item_net_sales,
  {{ money_cast('item_cost') }} as item_cost,
  {{ money_cast('item_gross_profit') }} as item_gross_profit,
  {{ timestamp_cast('created_at') }} as created_at
from {{ raw_relation('fact_order_items') }}
