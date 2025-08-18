{% macro safe_divide(numer, denom, default=0) -%}
case when {{ denom }} is null or {{ denom }} = 0 then {{ default }} else {{ numer }} / {{ denom }} end
{%- endmacro %}
