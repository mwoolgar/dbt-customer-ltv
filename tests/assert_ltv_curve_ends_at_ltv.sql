-- The last point of each channel's cumulative curve must equal that channel's LTV. Returns rows on failure.
select c.channel_name, c.cumulative_revenue_per_customer, r.ltv_revenue
from {{ ref('rpt_ltv_curve') }} c
join {{ ref('rpt_channel_ltv') }} r using (channel_name)
where c.months_since_first_order = {{ var('ltv_window_months') }}
  and abs(c.cumulative_revenue_per_customer - r.ltv_revenue) > 0.01
