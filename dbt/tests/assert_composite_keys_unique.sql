with violations as (
  select 'rank_history' as model_name
  from {{ ref('stg_dim_membership_rank_history') }}
  group by user_id, valid_from
  having count(*) > 1

  union all

  select 'identity_bridge'
  from {{ ref('stg_bridge_user_identity') }}
  group by user_pseudo_id, user_id, valid_from
  having count(*) > 1

  union all

  select 'campaign_cost'
  from {{ ref('stg_fact_campaign_cost_daily') }}
  group by cost_date, campaign_id
  having count(*) > 1

  union all

  select 'order_touchpoints'
  from {{ ref('int_order_touchpoints') }}
  group by order_id, touchpoint_sequence
  having count(*) > 1
)

select * from violations
