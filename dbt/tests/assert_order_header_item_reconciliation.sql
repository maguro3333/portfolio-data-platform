select
  coalesce(o.order_id, i.order_id) as order_id,
  o.gross_sales,
  i.item_gross_sales,
  o.discount_amount,
  i.item_discount_amount,
  o.item_net_sales,
  i.item_net_sales
from {{ ref('stg_fact_orders') }} o
full outer join {{ ref('int_order_items_agg') }} i
  on o.order_id = i.order_id
where o.order_id is null
  or i.order_id is null
  or abs(o.gross_sales - i.item_gross_sales) > 0.01
  or abs(o.discount_amount - i.item_discount_amount) > 0.01
  or abs(o.item_net_sales - i.item_net_sales) > 0.01
  or abs(o.order_total - (o.item_net_sales + o.tax_amount + o.shipping_amount)) > 0.01
