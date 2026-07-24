with event_steps as (
  select
    session_id,
    min(case when event_name = 'view_item' then event_sequence end) as view_sequence,
    min(case when event_name = 'add_to_cart' then event_sequence end) as cart_sequence,
    min(case when event_name = 'begin_checkout' then event_sequence end)
      as checkout_sequence,
    min(case when event_name = 'purchase' then event_sequence end) as purchase_sequence
  from {{ ref('stg_fact_events') }}
  group by session_id
),

first_viewed_product as (
  select session_id, product_id
  from (
    select
      session_id,
      product_id,
      row_number() over (
        partition by session_id
        order by event_sequence, event_id
      ) as product_rank
    from {{ ref('stg_fact_events') }}
    where event_name = 'view_item'
      and product_id is not null
  ) ranked
  where product_rank = 1
),

sequenced as (
  select
    s.session_id,
    s.session_date,
    s.user_id,
    s.source,
    s.medium,
    coalesce(s.campaign_id, '(none)') as campaign_id,
    s.device_category,
    s.is_engaged_session,
    p.product_id,
    coalesce(p.category_l1, '(not set)') as product_category_l1,
    e.view_sequence,
    case
      when e.cart_sequence > e.view_sequence then e.cart_sequence
    end as cart_sequence,
    case
      when e.checkout_sequence > e.cart_sequence
        and e.cart_sequence > e.view_sequence
        then e.checkout_sequence
    end as checkout_sequence,
    case
      when e.purchase_sequence > e.checkout_sequence
        and e.checkout_sequence > e.cart_sequence
        and e.cart_sequence > e.view_sequence
        then e.purchase_sequence
    end as purchase_sequence
  from {{ ref('stg_fact_sessions') }} s
  left join event_steps e
    on s.session_id = e.session_id
  left join first_viewed_product f
    on s.session_id = f.session_id
  left join {{ ref('stg_dim_products') }} p
    on f.product_id = p.product_id
)

select
  *,
  view_sequence is not null as reached_view_item,
  cart_sequence is not null as reached_add_to_cart,
  checkout_sequence is not null as reached_begin_checkout,
  purchase_sequence is not null as reached_purchase
from sequenced
