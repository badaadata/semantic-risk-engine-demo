WITH sales_transactions AS (
    SELECT
        order_id,
        customer_id AS retailer_id,
        amount AS sale_amount,
        order_date,
        CASE 
            WHEN amount > 250 THEN 0.15 
            WHEN amount > 100 THEN 0.05 
            ELSE 0.00 
        END AS discount_percentage
    FROM {{ ref('stg_orders') }}
    -- 1. Filter Logic Shift (status = 'completed' -> 'shipped')
    WHERE status = 'shipped'
),

retailer_demographics AS (
    SELECT
        customer_id AS retailer_id,
        region,
        is_active
    FROM {{ ref('stg_customers') }}
),

monthly_retail_sales AS (
    SELECT
        DATE_TRUNC('month', s.order_date) AS sales_month,
        s.retailer_id,
        r.region,
        COUNT(s.order_id) AS transactions_volume,
        SUM(s.sale_amount) AS gross_sales_revenue,
        SUM(s.sale_amount * (1.00 - s.discount_percentage)) AS net_sales_revenue
    FROM sales_transactions s
    -- 2. Join Condition Logic Shift (Added active filter to ON clause)
    INNER JOIN retailer_demographics r 
        ON s.retailer_id = r.retailer_id 
       AND r.is_active = TRUE
    GROUP BY 1, 2, 3
),

final_rollup AS (
    SELECT
        sales_month,
        retailer_id,
        region,
        transactions_volume,
        gross_sales_revenue,
        net_sales_revenue
    FROM monthly_retail_sales
)

SELECT * FROM final_rollup
-- 3. Qualify Logic Added
QUALIFY row_number() over (partition by retailer_id order by sales_month asc) = 1
