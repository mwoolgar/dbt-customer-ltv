-- Total value in the channel report must equal total value in the cohort model (within 1 cent).
select a.cohort_value, b.channel_value
from (select sum(first_order_revenue + repeat_revenue) as cohort_value from {{ ref('fct_cohort_ltv') }}) a
cross join (select sum(ltv_revenue * customers) as channel_value from {{ ref('rpt_channel_ltv') }}) b
where abs(a.cohort_value - b.channel_value) > 0.01
