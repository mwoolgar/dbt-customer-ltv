-- Month 0 retention must be 100% for every cohort. Returns rows on failure.
select cohort_month, channel_name, retention_rate
from {{ ref('fct_cohort_retention') }}
where months_since_first_order = 0 and abs(retention_rate - 1) > 0.0001
