/********************************************************************************
  SNOWFLAKE / DBT SEMANTIC RISK ENGINE STRESS TEST
  TOTAL LENGTH: 600+ LINES OF PURE SELECT / WITH ARCHITECTURE
  REAL BUSINESS LOGIC: E-COMMERCE FINANCIAL ATTRIBUTION & INVENTORY PIPELINE
********************************************************************************/

WITH prep_orders AS (
    SELECT
        order_id,
        customer_id,
        amount,
        status,
        order_date,
        updated_at
    FROM {{ ref('stg_orders') }}
),

prep_payments AS (
    SELECT
        payment_id,
        order_id,
        payment_method,
        payment_amount,
        paid_at
    FROM {{ ref('raw_orders') }} -- fallback for payments in duckdb demo seeds
),

prep_customers AS (
    SELECT
        customer_id,
        region,
        is_active,
        customer_id as customer_since -- fallback mapping
    FROM {{ ref('stg_customers') }}
),

regions_prep AS (
    -- Sync region metadata for joining
    SELECT 'US' AS alpha2_code, 'North America' AS region_name UNION ALL
    SELECT 'CA' AS alpha2_code, 'North America' AS region_name UNION ALL
    SELECT 'UK' AS alpha2_code, 'Europe' AS region_name
),

product_catalog AS (
    -- Detailed item dimensions including pricing, costs, and warehouse ids
    SELECT 'P001' AS product_id, 'Ultra Widget Pro' AS product_name, 'Electronics' AS category, 199.99 AS list_price, 85.00 AS cogs, 'WH-01' AS warehouse_id UNION ALL
    SELECT 'P002' AS product_id, 'Super Gadget Mini' AS product_name, 'Electronics' AS category, 89.99 AS list_price, 35.00 AS cogs, 'WH-01' AS warehouse_id UNION ALL
    SELECT 'P003' AS product_id, 'Eco Water Bottle 1L' AS product_name, 'Home & Kitchen' AS category, 29.99 AS list_price, 9.50 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P004' AS product_id, 'Smart Heated Mug' AS product_name, 'Home & Kitchen' AS category, 49.99 AS list_price, 18.00 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P005' AS product_id, 'Ergonomic Office Mouse' AS product_name, 'Office Supplies' AS category, 59.99 AS list_price, 22.00 AS cogs, 'WH-03' AS warehouse_id UNION ALL
    SELECT 'P006' AS product_id, 'LED Desk Lamp' AS product_name, 'Office Supplies' AS category, 39.99 AS list_price, 14.00 AS cogs, 'WH-03' AS warehouse_id UNION ALL
    SELECT 'P007' AS product_id, 'Premium Leather Journal' AS product_name, 'Stationery' AS category, 24.99 AS list_price, 7.50 AS cogs, 'WH-03' AS warehouse_id UNION ALL
    SELECT 'P008' AS product_id, 'Calligraphy Pen Set' AS product_name, 'Stationery' AS category, 14.99 AS list_price, 4.00 AS cogs, 'WH-03' AS warehouse_id UNION ALL
    SELECT 'P009' AS product_id, 'Fast Wireless Charger' AS product_name, 'Electronics' AS category, 45.00 AS list_price, 15.00 AS cogs, 'WH-01' AS warehouse_id UNION ALL
    SELECT 'P010' AS product_id, 'Eco-friendly Yoga Mat' AS product_name, 'Fitness' AS category, 55.00 AS list_price, 20.00 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P011' AS product_id, 'Resistance Bands 5-Pack' AS product_name, 'Fitness' AS category, 19.99 AS list_price, 6.50 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P012' AS product_id, 'Merino Running Socks' AS product_name, 'Apparel' AS category, 18.00 AS list_price, 5.00 AS cogs, 'WH-04' AS warehouse_id UNION ALL
    SELECT 'P013' AS product_id, 'Dry-fit Athletic Tee' AS product_name, 'Apparel' AS category, 34.99 AS list_price, 12.00 AS cogs, 'WH-04' AS warehouse_id UNION ALL
    SELECT 'P014' AS product_id, 'Organic Cotton Hoodie' AS product_name, 'Apparel' AS category, 65.00 AS list_price, 25.00 AS cogs, 'WH-04' AS warehouse_id UNION ALL
    SELECT 'P015' AS product_id, 'Waterproof Duffle Bag' AS product_name, 'Travel' AS category, 79.99 AS list_price, 30.00 AS cogs, 'WH-04' AS warehouse_id UNION ALL
    SELECT 'P016' AS product_id, 'Memory Foam Travel Pillow' AS product_name, 'Travel' AS category, 24.99 AS list_price, 9.00 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P017' AS product_id, 'Silk Sleep Eye Mask' AS product_name, 'Travel' AS category, 14.99 AS list_price, 4.50 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P018' AS product_id, 'Burr Coffee Grinder' AS product_name, 'Home & Kitchen' AS category, 119.99 AS list_price, 50.00 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P019' AS product_id, 'Double-walled French Press' AS product_name, 'Home & Kitchen' AS category, 39.99 AS list_price, 15.50 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P020' AS product_id, 'Smart Notebook Deluxe' AS product_name, 'Office Supplies' AS category, 29.99 AS list_price, 10.00 AS cogs, 'WH-03' AS warehouse_id UNION ALL
    SELECT 'P021' AS product_id, 'Noise Cancelling Earbuds' AS product_name, 'Electronics' AS category, 149.99 AS list_price, 65.00 AS cogs, 'WH-01' AS warehouse_id UNION ALL
    SELECT 'P022' AS product_id, 'Bluetooth Key Finder' AS product_name, 'Electronics' AS category, 29.99 AS list_price, 11.00 AS cogs, 'WH-01' AS warehouse_id UNION ALL
    SELECT 'P023' AS product_id, 'Chef Knife 8-inch' AS product_name, 'Home & Kitchen' AS category, 79.99 AS list_price, 32.00 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P024' AS product_id, 'Bamboo Cutting Board' AS product_name, 'Home & Kitchen' AS category, 24.99 AS list_price, 8.00 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P025' AS product_id, 'Standing Desk Converter' AS product_name, 'Office Supplies' AS category, 189.99 AS list_price, 90.00 AS cogs, 'WH-03' AS warehouse_id UNION ALL
    SELECT 'P026' AS product_id, 'Mesh Task Chair' AS product_name, 'Office Supplies' AS category, 220.00 AS list_price, 105.00 AS cogs, 'WH-03' AS warehouse_id UNION ALL
    SELECT 'P027' AS product_id, 'Recycled Paper Notebook' AS product_name, 'Stationery' AS category, 9.99 AS list_price, 2.50 AS cogs, 'WH-03' AS warehouse_id UNION ALL
    SELECT 'P028' AS product_id, 'Fountain Pen Classic' AS product_name, 'Stationery' AS category, 45.00 AS list_price, 16.00 AS cogs, 'WH-03' AS warehouse_id UNION ALL
    SELECT 'P029' AS product_id, 'Adjustable Dumbbells' AS product_name, 'Fitness' AS category, 299.99 AS list_price, 140.00 AS cogs, 'WH-02' AS warehouse_id UNION ALL
    SELECT 'P030' AS product_id, 'Heavy Duty Jump Rope' AS product_name, 'Fitness' AS category, 14.99 AS list_price, 4.50 AS cogs, 'WH-02' AS warehouse_id
),

web_clicks AS (
    -- Click logs containing session attributes, channels, campaigns, pageviews
    SELECT 1001 AS session_id, 1 AS customer_id, 'google' AS utm_source, 'cpc' AS utm_medium, 'spring_sale' AS utm_campaign, '2026-03-01 09:15:00'::TIMESTAMP AS session_date, 6 AS page_views UNION ALL
    SELECT 1002 AS session_id, 1 AS customer_id, 'facebook' AS utm_source, 'social' AS utm_medium, 'retargeting' AS utm_campaign, '2026-03-02 12:45:00'::TIMESTAMP AS session_date, 3 AS page_views UNION ALL
    SELECT 1003 AS session_id, 2 AS customer_id, 'direct' AS utm_source, 'direct' AS utm_medium, 'none' AS utm_campaign, '2026-03-05 08:30:00'::TIMESTAMP AS session_date, 2 AS page_views UNION ALL
    SELECT 1004 AS session_id, 3 AS customer_id, 'newsletter' AS utm_source, 'email' AS utm_medium, 'welcome_flow' AS utm_campaign, '2026-03-10 10:15:00'::TIMESTAMP AS session_date, 14 AS page_views UNION ALL
    SELECT 1005 AS session_id, 3 AS customer_id, 'google' AS utm_source, 'organic' AS utm_medium, 'none' AS utm_campaign, '2026-03-12 14:20:00'::TIMESTAMP AS session_date, 9 AS page_views UNION ALL
    SELECT 1006 AS session_id, 4 AS customer_id, 'partner' AS utm_source, 'affiliate' AS utm_medium, 'promo_code' AS utm_campaign, '2026-03-15 11:30:00'::TIMESTAMP AS session_date, 4 AS page_views UNION ALL
    SELECT 1007 AS session_id, 5 AS customer_id, 'youtube' AS utm_source, 'social' AS utm_medium, 'influencer_review' AS utm_campaign, '2026-03-20 17:10:00'::TIMESTAMP AS session_date, 8 AS page_views UNION ALL
    SELECT 1008 AS session_id, 6 AS customer_id, 'google' AS utm_source, 'cpc' AS utm_medium, 'spring_sale' AS utm_campaign, '2026-03-22 13:05:00'::TIMESTAMP AS session_date, 5 AS page_views UNION ALL
    SELECT 1009 AS session_id, 7 AS customer_id, 'direct' AS utm_source, 'direct' AS utm_medium, 'none' AS utm_campaign, '2026-03-25 15:40:00'::TIMESTAMP AS session_date, 2 AS page_views UNION ALL
    SELECT 1010 AS session_id, 8 AS customer_id, 'newsletter' AS utm_source, 'email' AS utm_medium, 'weekly_digest' AS utm_campaign, '2026-03-28 08:10:00'::TIMESTAMP AS session_date, 18 AS page_views UNION ALL
    SELECT 1011 AS session_id, 9 AS customer_id, 'google' AS utm_source, 'cpc' AS utm_medium, 'branding' AS utm_campaign, '2026-04-01 10:30:00'::TIMESTAMP AS session_date, 4 AS page_views UNION ALL
    SELECT 1012 AS session_id, 10 AS customer_id, 'facebook' AS utm_source, 'social' AS utm_medium, 'spring_sale' AS utm_campaign, '2026-04-03 16:50:00'::TIMESTAMP AS session_date, 7 AS page_views UNION ALL
    SELECT 1013 AS session_id, 11 AS customer_id, 'google' AS utm_source, 'organic' AS utm_medium, 'none' AS utm_campaign, '2026-04-05 09:00:00'::TIMESTAMP AS session_date, 3 AS page_views UNION ALL
    SELECT 1014 AS session_id, 12 AS customer_id, 'direct' AS utm_source, 'direct' AS utm_medium, 'none' AS utm_campaign, '2026-04-08 11:15:00'::TIMESTAMP AS session_date, 1 AS page_views UNION ALL
    SELECT 1015 AS session_id, 13 AS customer_id, 'newsletter' AS utm_source, 'email' AS utm_medium, 'welcome_flow' AS utm_campaign, '2026-04-10 10:45:00'::TIMESTAMP AS session_date, 12 AS page_views UNION ALL
    SELECT 1016 AS session_id, 14 AS customer_id, 'partner' AS utm_source, 'affiliate' AS utm_medium, 'referral_promo' AS utm_campaign, '2026-04-12 15:20:00'::TIMESTAMP AS session_date, 5 AS page_views UNION ALL
    SELECT 1017 AS session_id, 15 AS customer_id, 'google' AS utm_source, 'cpc' AS utm_medium, 'spring_sale' AS utm_campaign, '2026-04-15 13:00:00'::TIMESTAMP AS session_date, 6 AS page_views UNION ALL
    SELECT 1018 AS session_id, 16 AS customer_id, 'facebook' AS utm_source, 'social' AS utm_medium, 'retargeting' AS utm_campaign, '2026-04-18 14:40:00'::TIMESTAMP AS session_date, 4 AS page_views UNION ALL
    SELECT 1019 AS session_id, 17 AS customer_id, 'youtube' AS utm_source, 'social' AS utm_medium, 'influencer_review' AS utm_campaign, '2026-04-20 18:30:00'::TIMESTAMP AS session_date, 9 AS page_views UNION ALL
    SELECT 1020 AS session_id, 18 AS customer_id, 'newsletter' AS utm_source, 'email' AS utm_medium, 'weekly_digest' AS utm_campaign, '2026-04-22 09:10:00'::TIMESTAMP AS session_date, 15 AS page_views UNION ALL
    SELECT 1021 AS session_id, 19 AS customer_id, 'direct' AS utm_source, 'direct' AS utm_medium, 'none' AS utm_campaign, '2026-04-25 11:35:00'::TIMESTAMP AS session_date, 2 AS page_views UNION ALL
    SELECT 1022 AS session_id, 20 AS customer_id, 'google' AS utm_source, 'organic' AS utm_medium, 'none' AS utm_campaign, '2026-04-28 10:05:00'::TIMESTAMP AS session_date, 3 AS page_views UNION ALL
    SELECT 1023 AS session_id, 21 AS customer_id, 'google' AS utm_source, 'cpc' AS utm_medium, 'brand_protection' AS utm_campaign, '2026-05-01 13:50:00'::TIMESTAMP AS session_date, 5 AS page_views UNION ALL
    SELECT 1024 AS session_id, 22 AS customer_id, 'facebook' AS utm_source, 'social' AS utm_medium, 'retargeting' AS utm_campaign, '2026-05-03 15:10:00'::TIMESTAMP AS session_date, 6 AS page_views UNION ALL
    SELECT 1025 AS session_id, 23 AS customer_id, 'newsletter' AS utm_source, 'email' AS utm_medium, 'weekly_digest' AS utm_campaign, '2026-05-05 08:30:00'::TIMESTAMP AS session_date, 16 AS page_views UNION ALL
    SELECT 1026 AS session_id, 24 AS customer_id, 'partner' AS utm_source, 'affiliate' AS utm_medium, 'promo_code' AS utm_campaign, '2026-05-08 12:20:00'::TIMESTAMP AS session_date, 4 AS page_views UNION ALL
    SELECT 1027 AS session_id, 25 AS customer_id, 'youtube' AS utm_source, 'social' AS utm_medium, 'unboxing_video' AS utm_campaign, '2026-05-10 19:45:00'::TIMESTAMP AS session_date, 10 AS page_views UNION ALL
    SELECT 1028 AS session_id, 26 AS customer_id, 'google' AS utm_source, 'cpc' AS utm_medium, 'summer_preview' AS utm_campaign, '2026-05-12 11:15:00'::TIMESTAMP AS session_date, 7 AS page_views UNION ALL
    SELECT 1029 AS session_id, 27 AS customer_id, 'direct' AS utm_source, 'direct' AS utm_medium, 'none' AS utm_campaign, '2026-05-15 14:00:00'::TIMESTAMP AS session_date, 2 AS page_views UNION ALL
    SELECT 1030 AS session_id, 28 AS customer_id, 'newsletter' AS utm_source, 'email' AS utm_medium, 'summer_preview' AS utm_campaign, '2026-05-18 09:30:00'::TIMESTAMP AS session_date, 11 AS page_views
),

support_tickets AS (
    -- Customer service log mapping
    SELECT 2001 AS ticket_id, 1 AS customer_id, 'Billing' AS issue_category, 'High' AS severity, 'Closed' AS status, '2026-03-05 10:00:00'::TIMESTAMP AS created_at, '2026-03-05 14:00:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2002 AS ticket_id, 3 AS customer_id, 'Delivery Delay' AS issue_category, 'Medium' AS severity, 'Closed' AS status, '2026-03-15 13:00:00'::TIMESTAMP AS created_at, '2026-03-17 11:30:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2003 AS ticket_id, 5 AS customer_id, 'Defective Product' AS issue_category, 'High' AS severity, 'Closed' AS status, '2026-04-22 09:30:00'::TIMESTAMP AS created_at, '2026-04-24 16:00:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2004 AS ticket_id, 7 AS customer_id, 'Billing Error' AS issue_category, 'Low' AS severity, 'Closed' AS status, '2026-04-29 08:45:00'::TIMESTAMP AS created_at, '2026-04-29 10:15:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2005 AS ticket_id, 8 AS customer_id, 'Website Checkout Issue' AS issue_category, 'High' AS severity, 'Closed' AS status, '2026-05-02 15:30:00'::TIMESTAMP AS created_at, '2026-05-02 17:45:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2006 AS ticket_id, 10 AS customer_id, 'Wrong Size Sent' AS issue_category, 'Medium' AS severity, 'Closed' AS status, '2026-05-11 11:00:00'::TIMESTAMP AS created_at, '2026-05-12 15:00:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2007 AS ticket_id, 12 AS customer_id, 'Billing Dispute' AS issue_category, 'High' AS severity, 'Closed' AS status, '2026-05-14 09:30:00'::TIMESTAMP AS created_at, '2026-05-14 13:00:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2008 AS ticket_id, 15 AS customer_id, 'Package Lost' AS issue_category, 'High' AS severity, 'Closed' AS status, '2026-05-18 10:15:00'::TIMESTAMP AS created_at, '2026-05-20 09:00:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2010 AS ticket_id, 20 AS customer_id, 'Promo Code Failure' AS issue_category, 'Low' AS severity, 'Closed' AS status, '2026-05-24 11:30:00'::TIMESTAMP AS created_at, '2026-05-24 12:15:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2011 AS ticket_id, 22 AS customer_id, 'Delivery Delay' AS issue_category, 'Medium' AS severity, 'Closed' AS status, '2026-05-28 10:00:00'::TIMESTAMP AS created_at, '2026-05-29 14:00:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2012 AS ticket_id, 25 AS customer_id, 'Product Setup Help' AS issue_category, 'Low' AS severity, 'Closed' AS status, '2026-06-01 13:00:00'::TIMESTAMP AS created_at, '2026-06-01 15:30:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2013 AS ticket_id, 27 AS customer_id, 'Warranty Registration' AS issue_category, 'Low' AS severity, 'Closed' AS status, '2026-06-03 09:15:00'::TIMESTAMP AS created_at, '2026-06-03 10:45:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2014 AS ticket_id, 29 AS customer_id, 'Billing Error' AS issue_category, 'Medium' AS severity, 'Closed' AS status, '2026-06-05 14:40:00'::TIMESTAMP AS created_at, '2026-06-05 16:30:00'::TIMESTAMP AS resolved_at UNION ALL
    SELECT 2015 AS ticket_id, 30 AS customer_id, 'Package Damaged' AS issue_category, 'High' AS severity, 'Closed' AS status, '2026-06-07 10:30:00'::TIMESTAMP AS created_at, '2026-06-08 12:00:00'::TIMESTAMP AS resolved_at
),

campaign_ad_spend AS (
    -- Ad spend metrics by campaign name, channel, clicks, impressions
    SELECT 'spring_sale' AS campaign_name, 'google' AS channel_source, 'cpc' AS channel_medium, 1500.00 AS ad_spend, 12000 AS impressions UNION ALL
    SELECT 'spring_sale' AS campaign_name, 'facebook' AS channel_source, 'social' AS channel_medium, 1200.00 AS ad_spend, 8500 AS impressions UNION ALL
    SELECT 'retargeting' AS campaign_name, 'facebook' AS channel_source, 'social' AS channel_medium, 800.00 AS ad_spend, 4000 AS impressions UNION ALL
    SELECT 'welcome_flow' AS campaign_name, 'newsletter' AS channel_source, 'email' AS channel_medium, 150.00 AS ad_spend, 3000 AS impressions UNION ALL
    SELECT 'weekly_digest' AS campaign_name, 'newsletter' AS channel_source, 'email' AS channel_medium, 200.00 AS ad_spend, 4500 AS impressions UNION ALL
    SELECT 'influencer_review' AS campaign_name, 'youtube' AS channel_source, 'social' AS channel_medium, 2000.00 AS ad_spend, 25000 AS impressions UNION ALL
    SELECT 'branding' AS campaign_name, 'google' AS channel_source, 'cpc' AS channel_medium, 500.00 AS ad_spend, 3500 AS impressions UNION ALL
    SELECT 'brand_protection' AS campaign_name, 'google' AS channel_source, 'cpc' AS channel_medium, 300.00 AS ad_spend, 2000 AS impressions UNION ALL
    SELECT 'promo_code' AS campaign_name, 'partner' AS channel_source, 'affiliate' AS channel_medium, 400.00 AS ad_spend, 1500 AS impressions UNION ALL
    SELECT 'summer_preview' AS campaign_name, 'google' AS channel_source, 'cpc' AS channel_medium, 1000.00 AS ad_spend, 8000 AS impressions UNION ALL
    SELECT 'summer_preview' AS campaign_name, 'facebook' AS channel_source, 'social' AS channel_medium, 900.00 AS ad_spend, 7000 AS impressions UNION ALL
    SELECT 'summer_preview' AS campaign_name, 'newsletter' AS channel_source, 'email' AS channel_medium, 100.00 AS ad_spend, 2500 AS impressions UNION ALL
    SELECT 'referral_promo' AS campaign_name, 'partner' AS channel_source, 'affiliate' AS channel_medium, 250.00 AS ad_spend, 1000 AS impressions
),

shipping_logistics AS (
    -- Order delivery logs, carrier codes, transit details
    SELECT 3001 AS ship_log_id, 1 AS order_id, 'FedEx' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-03-02 09:00:00'::TIMESTAMP AS shipped_at, 3.99 AS actual_shipping_cost UNION ALL
    SELECT 3002 AS ship_log_id, 2 AS order_id, 'UPS' AS carrier, 'Express' AS service_level, 'Delivered' AS status, '2026-03-05 11:30:00'::TIMESTAMP AS shipped_at, 9.99 AS actual_shipping_cost UNION ALL
    SELECT 3003 AS ship_log_id, 3 AS order_id, 'DHL' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-03-10 14:15:00'::TIMESTAMP AS shipped_at, 5.99 AS actual_shipping_cost UNION ALL
    SELECT 3004 AS ship_log_id, 4 AS order_id, 'USPS' AS carrier, 'Economy' AS service_level, 'Delivered' AS status, '2026-03-16 10:00:00'::TIMESTAMP AS shipped_at, 2.99 AS actual_shipping_cost UNION ALL
    SELECT 3005 AS ship_log_id, 5 AS order_id, 'FedEx' AS carrier, 'Priority' AS service_level, 'Delivered' AS status, '2026-03-21 08:30:00'::TIMESTAMP AS shipped_at, 12.99 AS actual_shipping_cost UNION ALL
    SELECT 3006 AS ship_log_id, 6 AS order_id, 'UPS' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-03-23 15:45:00'::TIMESTAMP AS shipped_at, 4.99 AS actual_shipping_cost UNION ALL
    SELECT 3007 AS ship_log_id, 7 AS order_id, 'USPS' AS carrier, 'Economy' AS service_level, 'Delivered' AS status, '2026-03-26 09:00:00'::TIMESTAMP AS shipped_at, 2.99 AS actual_shipping_cost UNION ALL
    SELECT 3008 AS ship_log_id, 8 AS order_id, 'DHL' AS carrier, 'Priority' AS service_level, 'Delivered' AS status, '2026-03-29 11:00:00'::TIMESTAMP AS shipped_at, 14.99 AS actual_shipping_cost UNION ALL
    SELECT 3009 AS ship_log_id, 9 AS order_id, 'FedEx' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-04-02 13:30:00'::TIMESTAMP AS shipped_at, 3.99 AS actual_shipping_cost UNION ALL
    SELECT 3010 AS ship_log_id, 10 AS order_id, 'UPS' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-04-04 10:45:00'::TIMESTAMP AS shipped_at, 4.99 AS actual_shipping_cost UNION ALL
    SELECT 3011 AS ship_log_id, 11 AS order_id, 'FedEx' AS carrier, 'Express' AS service_level, 'Delivered' AS status, '2026-04-06 12:00:00'::TIMESTAMP AS shipped_at, 8.99 AS actual_shipping_cost UNION ALL
    SELECT 3012 AS ship_log_id, 12 AS order_id, 'UPS' AS carrier, 'Express' AS service_level, 'Delivered' AS status, '2026-04-09 14:30:00'::TIMESTAMP AS shipped_at, 9.99 AS actual_shipping_cost UNION ALL
    SELECT 3013 AS ship_log_id, 13 AS order_id, 'DHL' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-04-11 11:15:00'::TIMESTAMP AS shipped_at, 5.99 AS actual_shipping_cost UNION ALL
    SELECT 3014 AS ship_log_id, 14 AS order_id, 'USPS' AS carrier, 'Economy' AS service_level, 'Delivered' AS status, '2026-04-13 16:00:00'::TIMESTAMP AS shipped_at, 2.99 AS actual_shipping_cost UNION ALL
    SELECT 3015 AS ship_log_id, 15 AS order_id, 'FedEx' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-04-16 09:30:00'::TIMESTAMP AS shipped_at, 3.99 AS actual_shipping_cost UNION ALL
    SELECT 3016 AS ship_log_id, 16 AS order_id, 'UPS' AS carrier, 'Priority' AS service_level, 'Delivered' AS status, '2026-04-19 08:15:00'::TIMESTAMP AS shipped_at, 13.99 AS actual_shipping_cost UNION ALL
    SELECT 3017 AS ship_log_id, 17 AS order_id, 'USPS' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-04-21 14:00:00'::TIMESTAMP AS shipped_at, 4.99 AS actual_shipping_cost UNION ALL
    SELECT 3018 AS ship_log_id, 18 AS order_id, 'DHL' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-04-23 10:30:00'::TIMESTAMP AS shipped_at, 5.99 AS actual_shipping_cost UNION ALL
    SELECT 3019 AS ship_log_id, 19 AS order_id, 'FedEx' AS carrier, 'Economy' AS service_level, 'Delivered' AS status, '2026-04-26 11:45:00'::TIMESTAMP AS shipped_at, 2.99 AS actual_shipping_cost UNION ALL
    SELECT 3020 AS ship_log_id, 20 AS order_id, 'UPS' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-04-29 13:00:00'::TIMESTAMP AS shipped_at, 4.99 AS actual_shipping_cost UNION ALL
    SELECT 3021 AS ship_log_id, 21 AS order_id, 'FedEx' AS carrier, 'Express' AS service_level, 'Delivered' AS status, '2026-05-02 12:00:00'::TIMESTAMP AS shipped_at, 8.99 AS actual_shipping_cost UNION ALL
    SELECT 3022 AS ship_log_id, 22 AS order_id, 'UPS' AS carrier, 'Express' AS service_level, 'Delivered' AS status, '2026-05-04 15:30:00'::TIMESTAMP AS shipped_at, 9.99 AS actual_shipping_cost UNION ALL
    SELECT 3023 AS ship_log_id, 23 AS order_id, 'DHL' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-05-06 14:10:00'::TIMESTAMP AS shipped_at, 5.99 AS actual_shipping_cost UNION ALL
    SELECT 3024 AS ship_log_id, 24 AS order_id, 'USPS' AS carrier, 'Economy' AS service_level, 'Delivered' AS status, '2026-05-09 10:00:00'::TIMESTAMP AS shipped_at, 2.99 AS actual_shipping_cost UNION ALL
    SELECT 3025 AS ship_log_id, 25 AS order_id, 'FedEx' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-05-11 16:30:00'::TIMESTAMP AS shipped_at, 3.99 AS actual_shipping_cost UNION ALL
    SELECT 3026 AS ship_log_id, 26 AS order_id, 'UPS' AS carrier, 'Priority' AS service_level, 'Delivered' AS status, '2026-05-13 09:15:00'::TIMESTAMP AS shipped_at, 12.99 AS actual_shipping_cost UNION ALL
    SELECT 3027 AS ship_log_id, 27 AS order_id, 'USPS' AS carrier, 'Economy' AS service_level, 'Delivered' AS status, '2026-05-16 11:00:00'::TIMESTAMP AS shipped_at, 2.99 AS actual_shipping_cost UNION ALL
    SELECT 3028 AS ship_log_id, 28 AS order_id, 'DHL' AS carrier, 'Priority' AS service_level, 'Delivered' AS status, '2026-05-19 13:45:00'::TIMESTAMP AS shipped_at, 14.99 AS actual_shipping_cost UNION ALL
    SELECT 3029 AS ship_log_id, 29 AS order_id, 'FedEx' AS carrier, 'Standard' AS service_level, 'Delivered' AS status, '2026-05-22 10:20:00'::TIMESTAMP AS shipped_at, 3.99 AS actual_shipping_cost UNION ALL
    SELECT 3030 AS ship_log_id, 30 AS order_id, 'UPS' AS carrier, 'Express' AS service_level, 'Delivered' AS status, '2026-05-25 15:00:00'::TIMESTAMP AS shipped_at, 9.99 AS actual_shipping_cost
),

src_transactions AS (
    -- Consolidated modern and legacy data base input
    SELECT
        order_id AS txn_id,
        customer_id AS user_id,
        1 AS store_id,
        'electronics' AS product_category,
        amount AS txn_amount,
        'credit_card' AS payment_method,
        status,
        order_date AS txn_timestamp,
        order_date::DATE as txn_date
    FROM prep_orders
    WHERE status = 'completed'
      AND order_date >= '2024-01-01'
      AND amount > 0.00  -- BASE filter threshold
),

src_historical_archive AS (
    -- Historical archive lookup mapping
    SELECT
        order_id AS txn_id,
        customer_id AS user_id,
        2 AS store_id,
        'home_appliances' AS product_category,
        amount AS txn_amount,
        'bank_transfer' AS payment_method,
        status,
        order_date AS txn_timestamp,
        order_date::DATE as txn_date
    FROM prep_orders
    WHERE status = 'completed'
      AND order_date < '2024-01-01'
),

unified_ledger AS (
    -- Integration of modern and legacy pipelines
    SELECT * FROM src_transactions
    UNION ALL
    SELECT * FROM src_historical_archive
),

customer_base_demographics AS (
    -- Construction of customer master data
    SELECT
        customer_id,
        'US' AS country_code,
        customer_since AS signup_date,
        'LOW' AS risk_segment,
        TRUE AS is_active,
        -- Subquery for sync audit checking
        (SELECT MAX(updated_at) FROM prep_orders) AS last_audit_sync
    FROM prep_customers
    WHERE customer_id > 0
      -- BASE Filter polarity: EXISTS check
      AND EXISTS (
          SELECT 1 
          FROM prep_orders o 
          WHERE o.customer_id = prep_customers.customer_id
      )
),

regions_prep AS (
    -- Base regions mapper for geographic rollup
    SELECT 'US' AS alpha2_code, 'North America' AS region_name UNION ALL
    SELECT 'CA' AS alpha2_code, 'North America' AS region_name UNION ALL
    SELECT 'UK' AS alpha2_code, 'Europe' AS region_name
),

daily_transaction_grain AS (
    -- Daily revenue and aggregation metrics per user (with window functions)
    SELECT
        user_id,
        txn_date,
        COUNT(txn_id) AS daily_txn_count,
        SUM(txn_amount) AS total_daily_amount,
        AVG(txn_amount) AS avg_daily_amount,
        MAX(txn_amount) AS max_daily_amount,
        
        -- Analytics active duration tracking metrics
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY txn_date ASC) as customer_active_day_sequence,
        LAG(SUM(txn_amount), 1, 0.00) OVER (PARTITION BY user_id ORDER BY txn_date ASC) as prior_day_spend,
        LEAD(SUM(txn_amount), 1, 0.00) OVER (PARTITION BY user_id ORDER BY txn_date ASC) as next_day_spend,
        SUM(SUM(txn_amount)) OVER (PARTITION BY user_id ORDER BY txn_date ASC ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_7day_spend
    FROM unified_ledger
    GROUP BY user_id, txn_date
    HAVING COUNT(txn_id) >= 1 
       AND SUM(txn_amount) <= 500000.00
),

filtered_window_metrics AS (
    -- Filtering unnecessary data after window processing (QUALIFY)
    SELECT
        user_id,
        txn_date,
        daily_txn_count,
        total_daily_amount,
        rolling_7day_spend,
        customer_active_day_sequence
    FROM daily_transaction_grain
    QUALIFY customer_active_day_sequence <= 365
),

order_line_items AS (
    -- Cross-tabulation of order detail data
    SELECT
        o.order_id,
        c.product_id,
        c.product_name,
        c.category,
        c.list_price,
        c.cogs,
        1 + MOD(o.order_id * 3 + 2, 5) AS quantity,
        CASE WHEN MOD(o.order_id, 3) = 0 THEN 0.10 ELSE 0.00 END AS discount_rate,
        5.99 AS shipping_fee,
        0.08 AS tax_rate
    FROM prep_orders o
    CROSS JOIN product_catalog c
    WHERE MOD(o.order_id + CAST(SUBSTR(c.product_id, 3, 2) AS INT), 5) IN (0, 2)
),

item_financials AS (
    -- Details of revenue, tax, COGS, etc. for each order line item
    SELECT
        order_id,
        product_id,
        category,
        list_price,
        cogs,
        quantity,
        discount_rate,
        shipping_fee,
        tax_rate,
        list_price * (1.00 - discount_rate) AS unit_price,
        (list_price * (1.00 - discount_rate)) * quantity AS gross_item_revenue,
        ((list_price * (1.00 - discount_rate)) * quantity) * tax_rate AS item_tax,
        cogs * quantity AS total_item_cogs
    FROM order_line_items
),

order_financials AS (
    -- Order summary (tax, shipping cost, COGS, margin)
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        COUNT(DISTINCT f.product_id) AS product_count,
        SUM(f.quantity) AS total_items,
        SUM(f.gross_item_revenue) AS gross_revenue, 
        SUM(f.item_tax) AS total_tax,
        SUM(f.total_item_cogs) AS total_cogs,
        AVG(f.shipping_fee) AS base_shipping_fee,
        SUM(f.gross_item_revenue) - SUM(f.total_item_cogs) AS gross_margin
    FROM prep_orders o
    JOIN item_financials f ON o.order_id = f.order_id
    GROUP BY 1, 2, 3
),

customer_web_journeys AS (
    -- Acquisition channel, click log, and attribution analysis
    SELECT
        customer_id,
        utm_source,
        utm_medium,
        utm_campaign,
        session_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY session_date DESC) as click_recency_rank
    FROM web_clicks
),

last_click_attribution AS (
    -- Association of last click channel information
    SELECT
        customer_id,
        utm_source AS last_utm_source,
        utm_medium AS last_utm_medium,
        utm_campaign AS last_utm_campaign
    FROM customer_web_journeys
    WHERE click_recency_rank = 1
),

support_ticket_aggregates AS (
    -- Aggregation of customer support inquiries
    SELECT
        customer_id,
        COUNT(ticket_id) AS support_ticket_count,
        SUM(CASE WHEN severity = 'High' THEN 1 ELSE 0 END) AS high_priority_ticket_count
    FROM support_tickets
    GROUP BY 1
),

fulfillment_carrier_performance AS (
    -- Analysis of shipping delays and actual shipping costs by carrier
    SELECT
        s.carrier,
        COUNT(s.ship_log_id) AS total_shipments,
        AVG(s.actual_shipping_cost) AS avg_shipping_cost,
        SUM(CASE WHEN s.service_level = 'Express' THEN 1 ELSE 0 END) AS express_shipments_count
    FROM shipping_logistics s
    GROUP BY 1
),

payment_gateway_reconciliation AS (
    -- Reconciliation of payment fees and gateway revenue
    SELECT
        p.order_id,
        p.payment_method,
        p.payment_amount,
        p.paid_at,
        p.payment_amount * 0.025 AS gateway_fee
    FROM prep_payments p
),

customer_joined_mart AS (
    -- Comprehensive joined mart of customer info, attribution, and order details
    SELECT
        f.user_id,
        f.txn_date,
        f.daily_txn_count,
        f.total_daily_amount,
        f.rolling_7day_spend,
        f.customer_active_day_sequence,
        c.country_code,
        c.risk_segment,
        c.signup_date,
        lc.last_utm_source,
        lc.last_utm_campaign,
        sa.support_ticket_count,
        ofs.gross_revenue,
        ofs.gross_margin,
        ofs.total_tax,
        sl.carrier,
        sl.actual_shipping_cost
    FROM filtered_window_metrics f
    INNER JOIN customer_base_demographics c 
        ON f.user_id = c.customer_id
    LEFT JOIN regions_prep r 
        ON c.country_code = r.alpha2_code
    LEFT JOIN last_click_attribution lc 
        ON c.customer_id = lc.customer_id
    LEFT JOIN support_ticket_aggregates sa 
        ON c.customer_id = sa.customer_id
    LEFT JOIN order_financials ofs 
        ON f.user_id = ofs.customer_id
    LEFT JOIN shipping_logistics sl 
        ON ofs.order_id = sl.order_id
    -- BASE Join Condition: simple left join
    LEFT JOIN prep_payments p
        ON c.customer_id = p.order_id
    WHERE c.signup_date >= '2020-01-01'
),

risk_and_fraud_scoring AS (
    -- Evaluation of various indicators (AOV anomalies, support load, suspicious payment methods)
    SELECT
        user_id,
        txn_date,
        daily_txn_count,
        total_daily_amount,
        rolling_7day_spend,
        customer_active_day_sequence,
        country_code,
        risk_segment,
        gross_revenue,
        gross_margin,
        total_tax,
        actual_shipping_cost,
        carrier,
        CASE 
            WHEN total_daily_amount > 200.00 AND support_ticket_count >= 2 THEN 'HIGH_ALERT'
            WHEN total_daily_amount > 500.00 THEN 'REVIEW_NEEDED'
            ELSE 'NORMAL'
        END AS dynamic_risk_status
    FROM customer_joined_mart
),

retention_cohort_grid AS (
    -- Extraction of customer purchase activity by signup cohort
    SELECT
        DATE_TRUNC('month', signup_date) AS cohort_month,
        DATE_TRUNC('month', txn_date) AS activity_month,
        COUNT(DISTINCT user_id) AS active_users,
        SUM(total_daily_amount) AS cohort_spend
    FROM customer_joined_mart
    GROUP BY 1, 2
),

campaign_roas_performance AS (
    -- Return on Ad Spend (ROAS) measurement by advertising campaign
    SELECT
        a.campaign_name,
        a.channel_source,
        AVG(a.ad_spend) AS campaign_spend,
        SUM(cjm.gross_revenue) AS attributed_revenue,
        SUM(cjm.gross_revenue) / NULLIF(AVG(a.ad_spend), 0) AS campaign_roas
    FROM campaign_ad_spend a
    LEFT JOIN customer_joined_mart cjm 
        ON a.campaign_name = cjm.last_utm_campaign 
       AND a.channel_source = cjm.last_utm_source
    GROUP BY 1, 2
),

massive_risk_filter_layer AS (
    -- Final filtering layer
    SELECT
        r.user_id,
        r.txn_date,
        r.daily_txn_count,
        r.total_daily_amount,
        r.rolling_7day_spend,
        r.customer_active_day_sequence,
        r.country_code,
        r.risk_segment,
        r.gross_revenue,
        r.gross_margin,
        r.total_tax,
        r.actual_shipping_cost,
        r.carrier,
        r.dynamic_risk_status
    FROM risk_and_fraud_scoring r
    WHERE r.dynamic_risk_status = 'HIGH_ALERT'
      AND r.user_id IN (SELECT DISTINCT customer_id FROM customer_base_demographics WHERE is_active = TRUE)
)

-- MAIN TARGET EXECUTION LAYER
-- Final Grain: Unified Corporate Risk Reporting Metrics
SELECT
    m.user_id AS corporate_user_id,
    m.txn_date AS transaction_date,
    m.daily_txn_count AS daily_transaction_count,
    m.total_daily_amount AS daily_spend_amount,
    m.rolling_7day_spend AS weekly_spend_rolling,
    m.country_code AS geographic_region,
    m.risk_segment AS custom_risk_segment,
    m.dynamic_risk_status AS active_risk_status,
    
    SUM((m.total_daily_amount + m.rolling_7day_spend) + m.daily_txn_count) AS sum_nested_commutative,
    
    SUM(m.daily_txn_count * m.total_daily_amount + m.rolling_7day_spend * m.customer_active_day_sequence) AS mixed_operators_sum,
    SUM(m.rolling_7day_spend - m.total_daily_amount) AS non_commutative_sub,
    SUM((m.daily_txn_count + m.customer_active_day_sequence) * ABS(m.total_daily_amount - m.rolling_7day_spend)) AS complex_math_sum,
    SUM(ABS(m.rolling_7day_spend + m.total_daily_amount) + ROUND(m.daily_txn_count + m.customer_active_day_sequence, 2)) AS deep_mixed_sum,

    ROW_NUMBER() OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_1,
    RANK() OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_2,
    DENSE_RANK() OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_3,
    LEAD(m.total_daily_amount) OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_4,
    LAG(m.total_daily_amount) OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_5,
    SUM(m.total_daily_amount) OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_6,
    AVG(m.total_daily_amount) OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_7,
    COUNT(m.user_id) OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_8,
    MIN(m.total_daily_amount) OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_9,
    MAX(m.total_daily_amount) OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) as seq_low_10
FROM massive_risk_filter_layer m
WHERE m.dynamic_risk_status = 'HIGH_ALERT'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
QUALIFY ROW_NUMBER() OVER (PARTITION BY m.country_code ORDER BY m.total_daily_amount DESC) = 1
ORDER BY m.user_id ASC;
