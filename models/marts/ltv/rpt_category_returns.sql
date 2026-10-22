-- Grain: product category. Return rate = returned items / (valid + returned items). Cancelled items are ignored.
select
    p.category,
    countif(l.is_valid_sale or l.status = 'Returned')                       as items_sold,
    countif(l.status = 'Returned')                                          as items_returned,
    safe_divide(countif(l.status = 'Returned'), countif(l.is_valid_sale or l.status = 'Returned')) as return_rate,
    sum(if(l.status = 'Returned', l.net_revenue, 0))                        as returned_revenue
from {{ ref('fct_order_lines') }} l
join {{ ref('dim_product') }} p on p.product_key = l.product_key
group by 1
