with hourly as (
  select item_id, location_id,
         count(*) as snapshots_seen,
         sum(units_sold) as units_sold_so_far,
         max(datetime) as last_snapshot_at
  from {{ ref('stg_pos_hourly_today') }}
  group by 1,2
),
inv as (
  select
      item_id,
      location_id,
      onhand_qty as onhand_latest
  from {{ ref('stg_inventory_hourly_today') }}
  qualify row_number() over (
            partition by item_id, location_id
            order by datetime desc
         ) = 1
)
select
  e.*,
  coalesce(h.snapshots_seen, 0) as snapshots_seen,
  coalesce(h.units_sold_so_far, 0) as units_sold_so_far,
  {{ safe_divide('coalesce(h.snapshots_seen,0)','9',0) }} as day_elapsed_share,
  coalesce(i.onhand_latest, 0) as onhand_latest,
  h.last_snapshot_at
from {{ ref('int_pr_today_expectations') }} e
left join hourly h on h.item_id=e.item_id and h.location_id=e.location_id
left join inv i on i.item_id=e.item_id and i.location_id=e.location_id