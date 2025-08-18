select 
    cast(date as date) as date, 
    item_id, 
    location_id, 
    onhand_qty, 
    backroom_qty

from {{ source('promo','inventory_daily') }}