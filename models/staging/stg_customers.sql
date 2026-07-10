select customer_id, region, is_active
from {{ ref('raw_customers') }}
