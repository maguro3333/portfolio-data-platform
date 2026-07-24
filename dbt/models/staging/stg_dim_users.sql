select
  cast(user_sk as bigint) as user_sk,
  {{ string_cast('user_id') }} as user_id,
  {{ timestamp_cast('registration_at') }} as registration_at,
  lower({{ string_cast('registration_channel') }}) as registration_channel,
  lower({{ string_cast('acquisition_source') }}) as acquisition_source,
  lower({{ string_cast('acquisition_medium') }}) as acquisition_medium,
  {{ nullable_string('acquisition_campaign_id') }} as acquisition_campaign_id,
  {{ string_cast('country') }} as country,
  {{ string_cast('region') }} as region,
  {{ nullable_string('prefecture') }} as prefecture,
  {{ nullable_string('gender') }} as gender,
  {{ nullable_string('age_band') }} as age_band,
  lower({{ string_cast('membership_rank_current') }}) as membership_rank_current,
  {{ timestamp_cast('first_order_at') }} as first_order_at,
  {{ nullable_string('first_order_id') }} as first_order_id,
  {{ timestamp_cast('created_at') }} as created_at,
  {{ timestamp_cast('updated_at') }} as updated_at
from {{ raw_relation('dim_users') }}
