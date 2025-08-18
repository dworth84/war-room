select 
    location_id, 
    location_name, 
    region, 
    location_type 
    
from {{ source('promo','locations_dim') }}