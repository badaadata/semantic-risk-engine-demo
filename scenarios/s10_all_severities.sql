with revenue as (
    select customer_id, region, total_revenue, order_count
    from {{ ref('customer_revenue') }}
),
orders as (
    select order_id, customer_id, order_date, amount
    from {{ ref('stg_orders') }}
    where status = 'completed'
),
customers as (
    select customer_id, region, is_active
    from {{ ref('stg_customers') }}
),
order_ranked as (
    select o.order_id, o.customer_id, o.order_date, o.amount,
        -- HIGH: Window function partition removed
        row_number() over (order by o.order_date) as order_seq,
        sum(o.amount) over (partition by o.customer_id order by o.order_date) as running_total
    from orders o
),
first_orders as (
    select customer_id, order_date as first_order_date
    from order_ranked
    where order_seq = 1
),
customer_lifetime as (
    select orr.customer_id,
        count(orr.order_id) as lifetime_orders,
        sum(orr.amount) as lifetime_value,
        avg(orr.amount) as avg_order_value,
        max(orr.running_total) as peak_running_total
    from order_ranked orr
    group by orr.customer_id
),
enriched as (
    select cl.customer_id, c.region, c.is_active,
        cl.lifetime_orders, cl.lifetime_value, cl.avg_order_value,
        cl.peak_running_total
    from customer_lifetime cl
    left join customers c on cl.customer_id = c.customer_id
),
region_rollup as (
    select e.region,
        count(distinct e.customer_id) as customers,
        sum(e.lifetime_value) as region_ltv,
        avg(e.avg_order_value) as region_aov,
        sum(case when e.is_active then 1 else 0 end) as active_customers
    from enriched e
    -- HIGH: Join condition modified
    inner join revenue r on e.customer_id = r.customer_id and r.total_revenue > 10
    group by e.region
)
select region, customers, region_ltv, region_aov, active_customers,
    -- MEDIUM: Column formula scaled by 1.1
    region_ltv / nullif(customers * 1.1, 0) as ltv_per_customer,
    -- LOW: Window function added
    dense_rank() over (order by region_ltv desc) as ltv_rank
from region_rollup
-- MEDIUM: Filter threshold shifted from 0 to 250
where region_ltv > 250
-- HIGH: QUALIFY added
qualify ltv_rank <= 10
