-- Session source here (Adwords, YouTube, ...) is a different list from users.traffic_source (acquisition channel).
select
    id                  as event_id,
    user_id             as customer_id,
    session_id,
    traffic_source      as session_source,
    event_type,
    created_at,
    date(created_at)    as event_date
from {{ source('thelook', 'events') }}
where date(created_at) <= current_date()
