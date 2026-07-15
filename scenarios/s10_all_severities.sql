with base as (
    select 
        o.order_id, 
        o.customer_id, 
        o.order_date, 
        o.amount, 
        c.region,
        c.is_active
    from {{ ref('stg_orders') }} o
    left join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
)
select 
    order_id,
    customer_id,
    order_date,
    amount * 2 as gross_amount,
    region,
    is_active,
    row_number() over (partition by customer_id order by order_date asc) as transaction_sequence
from base
qualify transaction_sequence <= 50
