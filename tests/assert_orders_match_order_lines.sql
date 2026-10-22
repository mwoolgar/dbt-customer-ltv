-- Revenue and order counts in fct_orders must equal valid revenue and distinct orders in fct_order_lines. Returns rows on failure.
select a.line_revenue, b.order_revenue, a.line_orders, b.orders
from (select sum(net_revenue) as line_revenue, count(distinct order_id) as line_orders
      from {{ ref('fct_order_lines') }} where is_valid_sale) a
cross join (select sum(net_revenue) as order_revenue, count(*) as orders from {{ ref('fct_orders') }}) b
where abs(a.line_revenue - b.order_revenue) > 0.01 or a.line_orders != b.orders
