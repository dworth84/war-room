select 
    cast(datetime as timestamp) as datetime, 
    item_id, 
    location_id, 
    units_sold

from {{ source('promo','pos_hourly_today') }}