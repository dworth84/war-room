select 
    cast(date as date) as date, 
    location_id, 
    notes

from {{ source('promo','store_visit_notes') }}