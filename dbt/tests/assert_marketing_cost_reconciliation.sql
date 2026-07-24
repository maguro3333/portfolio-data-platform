with core as (
  select cost_date, campaign_id, sum(cost) as cost
  from {{ ref('stg_fact_campaign_cost_daily') }}
  group by cost_date, campaign_id
),

mart as (
  select metric_date as cost_date, campaign_id, sum(cost) as cost
  from {{ ref('mart_marketing_daily') }}
  where campaign_id <> '(none)'
  group by metric_date, campaign_id
)

select
  coalesce(c.cost_date, m.cost_date) as cost_date,
  coalesce(c.campaign_id, m.campaign_id) as campaign_id,
  c.cost as core_cost,
  m.cost as mart_cost
from core c
full outer join mart m
  on c.cost_date = m.cost_date
  and c.campaign_id = m.campaign_id
-- Compare values (coalescing absent sides to 0). A campaign-date that exists
-- only in the mart with zero spend (session/order activity, no ad cost that
-- day) is not a discrepancy; a genuine cost mismatch, or spend missing from
-- the mart, is.
where abs(coalesce(c.cost, 0) - coalesce(m.cost, 0)) > 0.01
