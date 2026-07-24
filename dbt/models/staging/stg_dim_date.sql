select
  cast(date_key as bigint) as date_key,
  cast(calendar_date as date) as calendar_date,
  cast(calendar_year as bigint) as calendar_year,
  cast(calendar_quarter as bigint) as calendar_quarter,
  cast(calendar_month as bigint) as calendar_month,
  {{ string_cast('year_month') }} as year_month,
  cast(iso_week as bigint) as iso_week,
  cast(day_of_month as bigint) as day_of_month,
  cast(day_of_week as bigint) as day_of_week,
  {{ string_cast('day_name') }} as day_name,
  {{ bool_cast('is_weekend') }} as is_weekend,
  {{ bool_cast('is_holiday') }} as is_holiday,
  {{ nullable_string('holiday_name') }} as holiday_name,
  {{ string_cast('season') }} as season,
  {{ bool_cast('is_sale_period') }} as is_sale_period,
  {{ nullable_string('sale_period_name') }} as sale_period_name
from {{ raw_relation('dim_date') }}
