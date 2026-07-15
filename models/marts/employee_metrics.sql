WITH employee_base AS (
    SELECT
        customer_id AS employee_id,
        region AS department,
        is_active,
        CASE 
            WHEN region = 'US' THEN '2021-01-15'::DATE
            WHEN region = 'CA' THEN '2022-06-01'::DATE
            ELSE '2023-09-10'::DATE
        END AS hire_date
    FROM {{ ref('stg_customers') }}
),

sales_achievements AS (
    SELECT
        customer_id AS employee_id,
        COUNT(order_id) AS total_deals_closed,
        SUM(amount) AS gross_sales_generated,
        AVG(amount) AS average_deal_size
    FROM {{ ref('stg_orders') }}
    WHERE status = 'completed'
    GROUP BY 1
),

payroll_calculations AS (
    SELECT
        e.employee_id,
        e.department,
        e.is_active,
        e.hire_date,
        CASE 
            WHEN e.department = 'US' THEN 95000.00
            WHEN e.department = 'CA' THEN 85000.00
            ELSE 70000.00
        END AS base_salary,
        COALESCE(s.gross_sales_generated * 0.05, 0.00) AS commission_earned,
        DATEDIFF('day', e.hire_date, '2026-07-01'::DATE) AS employee_tenure_days
    FROM employee_base e
    LEFT JOIN sales_achievements s ON e.employee_id = s.employee_id
),

tenure_benefits AS (
    SELECT
        employee_id,
        department,
        base_salary,
        commission_earned,
        base_salary + commission_earned AS total_compensation,
        CASE 
            WHEN employee_tenure_days > 1000 THEN base_salary * 0.10
            WHEN employee_tenure_days > 500 THEN base_salary * 0.05
            ELSE 0.00
        END AS tenure_bonus
    FROM payroll_calculations
    WHERE is_active = TRUE
)

SELECT
    department,
    COUNT(employee_id) AS active_employee_count,
    SUM(base_salary) AS total_department_base_payroll,
    SUM(commission_earned) AS total_commission_payout,
    SUM(tenure_bonus) AS total_loyalty_bonuses_paid,
    AVG(total_compensation) AS average_employee_compensation
FROM tenure_benefits
GROUP BY department
