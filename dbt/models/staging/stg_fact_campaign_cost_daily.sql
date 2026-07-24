select
  cast(cost_date as date) as cost_date,
  {{ string_cast('campaign_id') }} as campaign_id,
  {{ string_cast('platform') }} as platform,
  lower({{ string_cast('source') }}) as source,
  lower({{ string_cast('medium') }}) as medium,
  cast(impressions as bigint) as impressions,
  cast(clicks as bigint) as clicks,
  {{ money_cast('cost') }} as cost,
  upper({{ string_cast('currency') }}) as currency,
  {{ timestamp_cast('created_at') }} as created_at
from {{ raw_relation('fact_campaign_cost_daily') }}
