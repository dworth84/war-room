with prog as (select * from {{ ref('int_pr_today_progress') }}),
     kpis as (select * from {{ ref('int_pr_today_kpis') }}),
     imgs as (select * from {{ ref('int_pr_today_images') }}),
     items as (select * from {{ ref('stg_items') }}),
     locs  as (select * from {{ ref('stg_locations') }})

select
  /* Keys & context */
  p.item_id,
  i.item_name,
  i.category,
  p.location_id,
  l.location_name,
  l.region,

  /* Promo plan */
  p.promo_type,
  p.planned_lift,
  p.planned_price                            as price_plan,

  /* Prices */
  k.observed_price,

  /* Demand expectations */
  p.baseline_units,
  p.expected_day_units,

  /* Progress (hourly) */
  p.snapshots_seen,
  p.day_elapsed_share,
  p.units_sold_so_far,

  /* Expectations vs actual (to now) */
  (p.expected_day_units * p.day_elapsed_share)                                  as expected_so_far_units,
  ((p.expected_day_units * p.day_elapsed_share) - p.units_sold_so_far)          as trending_gap_units,

  /* Inventory signals */
  k.onhand_start,
  k.backroom_start,
  p.onhand_latest,
  k.osa_flag,
  k.root_cause_code,

  /* --- NEW: Price flags --- */
  k.price_mismatch_flag,
  k.price_mismatch_diff,

  /* --- NEW: Revenue metrics --- */
  (coalesce(k.observed_price, i.unit_price) * p.units_sold_so_far)              as revenue_so_far_usd,
  ((p.expected_day_units * p.day_elapsed_share) *
     coalesce(p.planned_price, k.observed_price, i.unit_price))                 as expected_revenue_so_far_usd,
  (((p.expected_day_units * p.day_elapsed_share) *
      coalesce(p.planned_price, k.observed_price, i.unit_price))
    - (coalesce(k.observed_price, i.unit_price) * p.units_sold_so_far))         as revenue_gap_so_far_usd,

  /* --- NEW: Efficiency/pace metrics --- */
  case
    when (p.expected_day_units * p.day_elapsed_share) > 0
      then p.units_sold_so_far / nullif((p.expected_day_units * p.day_elapsed_share), 0)
    else 0
  end                                                                            as pct_to_plan_so_far,

  p.units_sold_so_far / nullif(p.snapshots_seen, 0)                              as units_per_snapshot,
  (p.expected_day_units * p.day_elapsed_share) / nullif(p.snapshots_seen, 0)     as expected_units_per_snapshot,

  /* --- NEW: Operational flags --- */
  case
    when p.onhand_latest = 0 and k.backroom_start > 0 and p.day_elapsed_share < 0.8
      then 1 else 0
  end                                                                            as replenish_now_flag,

  case
    when p.snapshots_seen >= 3
         and (p.units_sold_so_far / nullif(p.snapshots_seen, 0)) = 0
         and p.day_elapsed_share <= 0.5
         and k.onhand_start > 0
      then 1 else 0
  end                                                                            as stalled_display_flag,

  /* Priority (includes price & replenishment boosts) */
  (
    greatest(0, (p.expected_day_units * p.day_elapsed_share) - p.units_sold_so_far)
      * coalesce(k.observed_price, i.unit_price)
    + case when k.price_mismatch_flag = 1 then 30 else 0 end
    + case when p.onhand_latest = 0 then 40 else 0 end
    + case when (p.onhand_latest = 0 and k.backroom_start > 0 and p.day_elapsed_share < 0.8) then 25 else 0 end
    + case when k.root_cause_code = 'SHELF_EXECUTION' then 50 else 0 end
  )                                                                              as priority_score,

  /* Existing quick flags */
  case when ((p.expected_day_units * p.day_elapsed_share) - p.units_sold_so_far) > 0 then 1 else 0 end as underperforming_flag,
  case when p.onhand_latest <= 2 then 1 else 0 end                                                     as oos_risk_flag,

  /* Images & recency */
  img.opening_image_url,
  img.midday_image_url,
  coalesce(img.midday_compliance_label, 'UNKNOWN')                              as midday_compliance_label,
  p.last_snapshot_at

from prog p
left join kpis k on k.item_id = p.item_id and k.location_id = p.location_id
left join imgs img on img.item_id = p.item_id and img.location_id = p.location_id
left join items i on i.item_id = p.item_id
left join locs  l on l.location_id = p.location_id
where p.date = current_date()
