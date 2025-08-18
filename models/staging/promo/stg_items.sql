select 
    item_id, 
    item_name, 
    category, 
    unit_price 

from {{ source('promo','items_dim') }}