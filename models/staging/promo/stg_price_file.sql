select 
cast(date as date) as date, 
item_id, 
location_id, 
price

from {{ source('promo','price_file') }}