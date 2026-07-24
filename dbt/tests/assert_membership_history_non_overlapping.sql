select
  a.user_id,
  a.valid_from,
  a.valid_to,
  b.valid_from as overlapping_valid_from,
  b.valid_to as overlapping_valid_to
from {{ ref('stg_dim_membership_rank_history') }} a
inner join {{ ref('stg_dim_membership_rank_history') }} b
  on a.user_id = b.user_id
  and a.valid_from < coalesce(b.valid_to, cast('9999-12-31' as date))
  and b.valid_from < coalesce(a.valid_to, cast('9999-12-31' as date))
  and a.valid_from < b.valid_from
