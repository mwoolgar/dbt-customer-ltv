-- Grain: one row per product
select
    product_id      as product_key,
    product_name,
    brand,
    category,
    department,
    cost,
    retail_price
from {{ ref('stg_thelook__products') }}
