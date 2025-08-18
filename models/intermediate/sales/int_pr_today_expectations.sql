select
  p.date,
  p.item_id,
  p.location_id,
  p.promo_type,
  p.planned_lift,
  p.planned_price,
  b.baseline_units,
  (b.baseline_units * p.planned_lift) as expected_day_units

from {{ ref('stg_promo_calendar') }} p

join {{ ref('stg_baseline_units') }} b
  on b.item_id = p.item_id and b.location_id = p.location_id
where p.date = current_date()