-- Customers in fct_cohort_ltv must equal mature customers in fct_customer_ltv. Returns rows on failure.
select a.cohort_customers, b.mature_customers
from (select sum(customers) as cohort_customers from {{ ref('fct_cohort_ltv') }}) a
cross join (select count(*) as mature_customers from {{ ref('fct_customer_ltv') }} where is_mature_cohort) b
where a.cohort_customers != b.mature_customers
