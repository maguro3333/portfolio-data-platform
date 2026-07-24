select
  {{ string_cast('user_pseudo_id') }} as user_pseudo_id,
  {{ string_cast('user_id') }} as user_id,
  {{ timestamp_cast('valid_from') }} as valid_from,
  {{ timestamp_cast('valid_to') }} as valid_to,
  lower({{ string_cast('identity_source') }}) as identity_source,
  {{ bool_cast('is_current') }} as is_current,
  {{ timestamp_cast('created_at') }} as created_at
from {{ raw_relation('bridge_user_identity') }}
