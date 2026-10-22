-- Grain: one row per acquisition channel (users.traffic_source)
select distinct
    {{ channel_key('traffic_source') }}     as channel_key,
    coalesce(traffic_source, 'Unknown')     as channel_name
from {{ ref('stg_thelook__users') }}
