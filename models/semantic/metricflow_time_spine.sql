-- Required by the dbt Semantic Layer / MetricFlow for any ratio or cumulative metric that spans
-- time grains. Reuses dim_date rather than generating its own date range, so it stays in sync with
-- the star schema's own calendar (see dbt_project.yml var date_spine_start).
select date_day
from {{ ref('dim_date') }}
