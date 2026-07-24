select
  {{ string_cast('campaign_id') }} as campaign_id,
  {{ string_cast('campaign_name') }} as campaign_name,
  {{ string_cast('platform') }} as platform,
  lower({{ string_cast('source') }}) as source,
  lower({{ string_cast('medium') }}) as medium,
  lower({{ string_cast('campaign_type') }}) as campaign_type,
  cast(start_date as date) as start_date,
  cast(end_date as date) as end_date,
  {{ bool_cast('is_paid') }} as is_paid,
  {{ timestamp_cast('created_at') }} as created_at,
  {{ timestamp_cast('updated_at') }} as updated_at
from {{ raw_relation('dim_campaign') }}
