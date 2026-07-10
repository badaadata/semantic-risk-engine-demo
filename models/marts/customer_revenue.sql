WITH orders AS (
  SELECT order_id, customer_id, order_date, amount
  FROM {{ ref('stg_orders') }}
  WHERE status = 'completed'
)
-- monthly revenue rollup per customer
SELECT o.customer_id,
       c.region,
       COUNT(o.order_id) AS order_count,
       SUM(o.amount)     AS total_revenue
FROM orders o
LEFT JOIN {{ ref('stg_customers') }} c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.region
