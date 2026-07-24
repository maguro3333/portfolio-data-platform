select *
from {{ ref('int_session_funnel') }}
where reached_purchase and not reached_begin_checkout
  or reached_begin_checkout and not reached_add_to_cart
  or reached_add_to_cart and not reached_view_item
  or purchase_sequence is not null and purchase_sequence <= checkout_sequence
  or checkout_sequence is not null and checkout_sequence <= cart_sequence
  or cart_sequence is not null and cart_sequence <= view_sequence
