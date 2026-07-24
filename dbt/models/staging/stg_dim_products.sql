select
  cast(product_sk as bigint) as product_sk,
  {{ string_cast('product_id') }} as product_id,
  {{ string_cast('product_name') }} as product_name,
  {{ string_cast('brand') }} as brand,
  {{ string_cast('category_l1') }} as category_l1,
  {{ string_cast('category_l2') }} as category_l2,
  {{ money_cast('list_price') }} as list_price,
  {{ money_cast('standard_cost') }} as standard_cost,
  cast(launch_date as date) as launch_date,
  {{ bool_cast('is_active') }} as is_active,
  {{ timestamp_cast('created_at') }} as created_at,
  {{ timestamp_cast('updated_at') }} as updated_at
from {{ raw_relation('dim_products') }}
