with imgs as (
  select * from {{ ref('stg_shelf_images') }} where date = current_date()
)
select
  item_id, location_id,
  max(case when image_role='opening' then image_url end) as opening_image_url,
  max(case when image_role='midday'  then image_url end) as midday_image_url,
  max(case when image_role='midday'  then compliance_label end) as midday_compliance_label
from imgs
group by 1,2