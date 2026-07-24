{% macro date_add_days(date_expression, days) -%}
  {{ return(adapter.dispatch('date_add_days', 'ec_portfolio')(date_expression, days)) }}
{%- endmacro %}

{% macro duckdb__date_add_days(date_expression, days) -%}
  ({{ date_expression }} + interval '{{ days }} day')
{%- endmacro %}

{% macro bigquery__date_add_days(date_expression, days) -%}
  timestamp_add({{ date_expression }}, interval {{ days }} day)
{%- endmacro %}

{% macro athena__date_add_days(date_expression, days) -%}
  date_add('day', {{ days }}, {{ date_expression }})
{%- endmacro %}

{% macro month_start(date_expression) -%}
  {{ return(adapter.dispatch('month_start', 'ec_portfolio')(date_expression)) }}
{%- endmacro %}

{% macro default__month_start(date_expression) -%}
  cast(date_trunc('month', {{ date_expression }}) as date)
{%- endmacro %}

{% macro bigquery__month_start(date_expression) -%}
  date_trunc(cast({{ date_expression }} as date), month)
{%- endmacro %}

{% macro month_diff(start_expression, end_expression) -%}
  {{ return(adapter.dispatch('month_diff', 'ec_portfolio')(start_expression, end_expression)) }}
{%- endmacro %}

{% macro month_end(date_expression) -%}
  {{ return(adapter.dispatch('month_end', 'ec_portfolio')(date_expression)) }}
{%- endmacro %}

{% macro duckdb__month_end(date_expression) -%}
  cast(
    date_trunc('month', {{ date_expression }})
    + interval '1 month' - interval '1 day'
    as date
  )
{%- endmacro %}

{% macro athena__month_end(date_expression) -%}
  last_day_of_month(cast({{ date_expression }} as date))
{%- endmacro %}

{% macro bigquery__month_end(date_expression) -%}
  last_day(cast({{ date_expression }} as date), month)
{%- endmacro %}

{% macro day_diff(start_expression, end_expression) -%}
  {{ return(adapter.dispatch('day_diff', 'ec_portfolio')(start_expression, end_expression)) }}
{%- endmacro %}

{% macro duckdb__day_diff(start_expression, end_expression) -%}
  date_diff('day', cast({{ start_expression }} as date), cast({{ end_expression }} as date))
{%- endmacro %}

{% macro athena__day_diff(start_expression, end_expression) -%}
  date_diff('day', cast({{ start_expression }} as date), cast({{ end_expression }} as date))
{%- endmacro %}

{% macro bigquery__day_diff(start_expression, end_expression) -%}
  date_diff(cast({{ end_expression }} as date), cast({{ start_expression }} as date), day)
{%- endmacro %}

{% macro duckdb__month_diff(start_expression, end_expression) -%}
  date_diff('month', {{ start_expression }}, {{ end_expression }})
{%- endmacro %}

{% macro athena__month_diff(start_expression, end_expression) -%}
  date_diff('month', {{ start_expression }}, {{ end_expression }})
{%- endmacro %}

{% macro bigquery__month_diff(start_expression, end_expression) -%}
  date_diff(cast({{ end_expression }} as date), cast({{ start_expression }} as date), month)
{%- endmacro %}

{% macro safe_divide(numerator, denominator) -%}
  {{ return(adapter.dispatch('safe_divide', 'ec_portfolio')(numerator, denominator)) }}
{%- endmacro %}

{% macro default__safe_divide(numerator, denominator) -%}
  cast({{ numerator }} as decimal(38, 6))
  / nullif(cast({{ denominator }} as decimal(38, 6)), 0)
{%- endmacro %}

{% macro duckdb__safe_divide(numerator, denominator) -%}
  cast({{ numerator }} as decimal(38, 6))
  / nullif(cast({{ denominator }} as decimal(38, 6)), 0)
{%- endmacro %}

{% macro athena__safe_divide(numerator, denominator) -%}
  cast({{ numerator }} as decimal(38, 6))
  / nullif(cast({{ denominator }} as decimal(38, 6)), 0)
{%- endmacro %}

{% macro bigquery__safe_divide(numerator, denominator) -%}
  cast({{ numerator }} as numeric)
  / nullif(cast({{ denominator }} as numeric), 0)
{%- endmacro %}

{% macro money_cast(expression) -%}
  {{ return(adapter.dispatch('money_cast', 'ec_portfolio')(expression)) }}
{%- endmacro %}

{% macro default__money_cast(expression) -%}
  cast({{ expression }} as decimal(18, 2))
{%- endmacro %}

{% macro duckdb__money_cast(expression) -%}
  cast({{ expression }} as decimal(18, 2))
{%- endmacro %}

{% macro athena__money_cast(expression) -%}
  cast({{ expression }} as decimal(18, 2))
{%- endmacro %}

{% macro bigquery__money_cast(expression) -%}
  cast(round(cast({{ expression }} as numeric), 2) as numeric)
{%- endmacro %}

{% macro rate_cast(expression) -%}
  {{ return(adapter.dispatch('rate_cast', 'ec_portfolio')(expression)) }}
{%- endmacro %}

{% macro default__rate_cast(expression) -%}
  cast({{ expression }} as decimal(18, 6))
{%- endmacro %}

{% macro duckdb__rate_cast(expression) -%}
  cast({{ expression }} as decimal(18, 6))
{%- endmacro %}

{% macro athena__rate_cast(expression) -%}
  cast({{ expression }} as decimal(18, 6))
{%- endmacro %}

{% macro bigquery__rate_cast(expression) -%}
  cast(round(cast({{ expression }} as numeric), 6) as numeric)
{%- endmacro %}

{% macro bool_cast(expression) -%}
  {{ return(adapter.dispatch('bool_cast', 'ec_portfolio')(expression)) }}
{%- endmacro %}

{% macro duckdb__bool_cast(expression) -%}
  cast(nullif({{ expression }}, '') as boolean)
{%- endmacro %}

{% macro default__bool_cast(expression) -%}
  cast({{ expression }} as boolean)
{%- endmacro %}

{% macro timestamp_cast(expression) -%}
  {{ return(adapter.dispatch('timestamp_cast', 'ec_portfolio')(expression)) }}
{%- endmacro %}

{% macro duckdb__timestamp_cast(expression) -%}
  cast(replace(nullif({{ expression }}, ''), 'Z', '+00:00') as timestamp)
{%- endmacro %}

{% macro athena__timestamp_cast(expression) -%}
  cast(from_iso8601_timestamp(nullif({{ expression }}, '')) as timestamp)
{%- endmacro %}

{% macro default__timestamp_cast(expression) -%}
  cast({{ expression }} as timestamp)
{%- endmacro %}

{% macro nullable_string(expression) -%}
  nullif(trim({{ expression }}), '')
{%- endmacro %}

{% macro string_cast(expression) -%}
  {{ return(adapter.dispatch('string_cast', 'ec_portfolio')(expression)) }}
{%- endmacro %}

{% macro default__string_cast(expression) -%}
  cast({{ expression }} as varchar)
{%- endmacro %}

{% macro bigquery__string_cast(expression) -%}
  cast({{ expression }} as string)
{%- endmacro %}
