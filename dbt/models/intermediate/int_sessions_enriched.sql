select
  s.*,
  case
    when s.user_id is null then 'anonymous'
    when u.first_order_at is null or s.session_start_at <= u.first_order_at then 'new'
    else 'existing'
  end as customer_type
from {{ ref('stg_fact_sessions') }} s
left join {{ ref('stg_dim_users') }} u
  on s.user_id = u.user_id
