select 
    item_id, 
    location_id, 
    baseline_units 

from {{ source('promo','baseline_units') }}