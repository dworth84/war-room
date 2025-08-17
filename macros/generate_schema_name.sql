-- macros/generate_schema_name.sql
{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- if custom_schema_name is not none -%}
    {{ custom_schema_name }}          {# use exactly what you set #}
  {%- else -%}
    {{ target.schema }}               {# fallback to target.schema #}
  {%- endif -%}
{%- endmacro %}
