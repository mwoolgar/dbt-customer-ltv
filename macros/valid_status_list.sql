{# Renders the valid_statuses var as a SQL list: 'Complete','Shipped','Processing' #}
{% macro valid_status_list() -%}
{{ "'" ~ var('valid_statuses') | join("','") ~ "'" }}
{%- endmacro %}
