select *
from {{ ref('mart_rfm_segment_daily') }}
where customers < {{ var('public_min_customers') }}
