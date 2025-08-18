select 
cast(datetime as timestamp) as datetime, 
item_id, 
location_id, 
onhand_qty

from {{ source('promo','inventory_hourly_today') }}