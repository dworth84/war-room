with pos as (
  -- bring POS dollars/units (and price if your staging exposes it)
  select
    date,
    item_id,
    location_id,
    units_sold,
    net_sales,
    /* if your stg_pos_daily doesn't expose a price col, this will be null and we'll fall back */
    observed_price as pos_price
  from {{ ref('stg_pos_daily') }}
  where date = current_date()
),
inv as (
  select date, item_id, location_id, onhand_qty, backroom_qty
  from {{ ref('stg_inventory_daily') }}
  where date = current_date()
),
pr as (
  select date, item_id, location_id, promo_type, planned_lift, planned_price
  from {{ ref('stg_promo_calendar') }}
  where date = current_date()
),
pf as (
  select date, item_id, location_id, price
  from {{ ref('stg_price_file') }}
  where date = current_date()
)

select
  p.date,
  p.item_id,
  p.location_id,

  /* POS activity */
  p.units_sold                                   as actual_units_daily,

  /* Observed (register) price: POS dollars/units → else POS price column → else price file */
  coalesce(
    case when p.units_sold > 0 then p.net_sales / nullif(p.units_sold, 0) end,
    p.pos_price,
    pf.price
  )                                              as observed_price,

  /* Promo plan context */
  pr.planned_price,
  pr.promo_type,
  pr.planned_lift,

  /* Inventory context at open (daily snapshot) */
  inv.onhand_qty                                 as onhand_start,
  inv.backroom_qty                               as backroom_start,
  case when inv.onhand_qty > 0 then 1 else 0 end as osa_flag,

  /* Simple inventory-side root cause */
  case
    when inv.onhand_qty = 0 then 'OOS_AT_OPEN'
    when inv.backroom_qty > 0 and inv.onhand_qty <= 2 then 'SHELF_EXECUTION'
    else null
  end                                             as root_cause_code,

  /* --- PRICE FLAGS --- */
  case
    when pr.planned_price is not null
     and coalesce(
           case when p.units_sold > 0 then p.net_sales / nullif(p.units_sold, 0) end,
           p.pos_price,
           pf.price
         ) is not null
     and abs(
           coalesce(
             case when p.units_sold > 0 then p.net_sales / nullif(p.units_sold, 0) end,
             p.pos_price,
             pf.price
           ) - pr.planned_price
         ) > 0.01
    then 1 else 0
  end                                             as price_mismatch_flag,

  abs(
    coalesce(
      case when p.units_sold > 0 then p.net_sales / nullif(p.units_sold, 0) end,
      p.pos_price,
      pf.price
    ) - pr.planned_price
  )                                               as price_mismatch_diff

from pos p
left join inv on inv.date = p.date and inv.item_id = p.item_id and inv.location_id = p.location_id
left join pr  on  pr.date = p.date and  pr.item_id = p.item_id and  pr.location_id = p.location_id
left join pf  on  pf.date = p.date and  pf.item_id = p.item_id and  pf.location_id = p.location_id
