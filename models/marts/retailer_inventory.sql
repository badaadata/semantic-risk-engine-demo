WITH product_sales AS (
    SELECT
        order_id,
        amount AS sale_amount,
        order_date,
        CASE 
            WHEN MOD(order_id, 3) = 0 THEN 'Electronics'
            WHEN MOD(order_id, 3) = 1 THEN 'Apparel'
            ELSE 'Home & Kitchen'
        END AS product_category
    FROM {{ ref('stg_orders') }}
    WHERE status = 'completed'
),

inventory_metrics AS (
    SELECT
        product_category,
        COUNT(order_id) AS total_units_sold,
        SUM(sale_amount) AS total_revenue_generated,
        AVG(sale_amount) * 0.40 AS average_holding_cost
    FROM product_sales
    GROUP BY 1
)

SELECT
    product_category,
    total_units_sold,
    total_revenue_generated,
    average_holding_cost,
    total_revenue_generated / NULLIF(average_holding_cost * 1.5, 0) AS stock_turnover_ratio
FROM inventory_metrics
