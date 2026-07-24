{#
  Target-aware schema routing.

  - duckdb (local): keep dbt's default "<target_schema>_<custom>" behaviour so
    local validation is unchanged (e.g. analytics_staging, analytics_marts).
  - bigquery: map the logical folder schemas onto the Terraform-managed
    datasets (ec_staging / ec_core / ec_mart), keeping customer-grain internal
    models in a separate dataset from public-safe ones.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- set default_schema = target.schema -%}
  {%- if custom_schema_name is none -%}
    {{ default_schema }}
  {%- elif target.type in ['bigquery', 'athena'] -%}
    {%- set warehouse_map = {
      'staging': 'ec_staging',
      'intermediate': 'ec_core',
      'marts': 'ec_mart',
      'internal': 'ec_mart_internal',
      'public': 'ec_mart'
    } -%}
    {{ warehouse_map.get(custom_schema_name | trim, default_schema ~ '_' ~ (custom_schema_name | trim)) }}
  {%- else -%}
    {{ default_schema }}_{{ custom_schema_name | trim }}
  {%- endif -%}
{%- endmacro %}
