{% macro raw_relation(table_name) -%}
  {{ return(adapter.dispatch('raw_relation', 'ec_portfolio')(table_name)) }}
{%- endmacro %}

{% macro duckdb__raw_relation(table_name) -%}
  read_csv_auto(
    '{{ var("raw_data_path") }}/{{ table_name }}/*.csv.gz',
    header = true,
    all_varchar = true,
    union_by_name = true
  )
{%- endmacro %}

{% macro default__raw_relation(table_name) -%}
  {{ source('raw', table_name) }}
{%- endmacro %}
