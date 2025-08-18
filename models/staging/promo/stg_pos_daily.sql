select 
    cast(date as date) as date, 
    item_id, 
    location_id, 
    units_sold, 
    price as observed_price, 
    net_sales, 
    promo_flag

from {{ source('promo','pos_daily') }}