select 
    cast(date as date) as date, 
    item_id, 
    location_id,
    cast(capture_time as timestamp) as capture_time,
    image_role, 
    image_url, 
    compliance_label, 
    notes

from {{ source('promo','shelf_images') }}
