-- Grain: one row per calendar day
select
    cast(format_date('%Y%m%d', d) as int64)     as date_key,
    d                                           as date_day,
    date_trunc(d, month)                        as month_start,
    format_date('%Y-%m', d)                     as year_month,
    extract(year from d)                        as year,
    extract(quarter from d)                     as quarter,
    extract(month from d)                       as month_number,
    format_date('%B', d)                        as month_name,
    format_date('%A', d)                        as day_name,
    extract(dayofweek from d) in (1, 7)         as is_weekend
from unnest(generate_date_array(
    date('{{ var("date_spine_start") }}'),
    date_add(current_date(), interval 1 year)
)) as d
