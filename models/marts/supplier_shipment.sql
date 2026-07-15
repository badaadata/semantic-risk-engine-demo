WITH order_regions AS (
    SELECT
        o.order_id,
        o.amount AS shipping_fee,
        c.region AS destination_region,
        o.order_date
    FROM {{ ref('stg_orders') }} o
    INNER JOIN {{ ref('stg_customers') }} c ON o.customer_id = c.customer_id
    WHERE o.status = 'shipped'
),

carrier_aggregates AS (
    SELECT
        destination_region,
        COUNT(order_id) AS total_shipments,
        SUM(shipping_fee) AS total_shipping_fee,
        AVG(shipping_fee) AS average_shipping_fee
    FROM order_regions
    GROUP BY 1
)

SELECT
    destination_region,
    total_shipments,
    total_shipping_fee,
    average_shipping_fee
FROM carrier_aggregates
