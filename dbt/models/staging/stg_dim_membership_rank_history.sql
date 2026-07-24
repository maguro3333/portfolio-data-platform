select
  {{ string_cast('user_id') }} as user_id,
  lower({{ string_cast('membership_rank') }}) as membership_rank,
  cast(valid_from as date) as valid_from,
  cast(nullif(valid_to, '') as date) as valid_to,
  {{ bool_cast('is_current') }} as is_current,
  {{ timestamp_cast('created_at') }} as created_at
from {{ raw_relation('dim_membership_rank_history') }}
