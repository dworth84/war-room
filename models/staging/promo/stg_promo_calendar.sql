select 
    cast(date as date) as date, 
    item_id, 
    location_id,
    promo_flag, 
    promo_type, 
    planned_lift, 
    planned_price

from {{ source('promo','promo_calendar') }}