{# Deterministic surrogate key for the channel dimension (acquisition traffic source). #}
{% macro channel_key(column_name) -%}
to_hex(md5(coalesce({{ column_name }}, 'Unknown')))
{%- endmacro %}
