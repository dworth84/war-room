select location_id, 
item_id, 
category, 
target_facings, 
shelf_position

from {{ source('promo','planogram') }}