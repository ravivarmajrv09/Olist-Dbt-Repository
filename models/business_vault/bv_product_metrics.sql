{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='product_hk',
    schema='BUSINESS_VAULT'
) }}

WITH product_orders AS (

    SELECT
        l.product_hk,
        l.order_item_hk,
        s.price,
        s.freight_value,
        s.load_date,
        s.record_source

    FROM {{ ref('link_order_item') }} l

    INNER JOIN {{ ref('sat_order_item') }} s
        ON l.order_item_hk = s.order_item_hk

    {% if is_incremental() %}

    WHERE s.load_date >= (
        SELECT COALESCE(
            MAX(load_date),
            '1900-01-01'::TIMESTAMP_NTZ
        )
        FROM {{ this }}
    )

    {% endif %}

),

product_metrics AS (

    SELECT
        product_hk,

        COUNT(DISTINCT order_item_hk) AS total_items_sold,

        SUM(price) AS total_product_revenue,

        SUM(freight_value) AS total_freight_value,

        SUM(price + freight_value) AS total_revenue,

        MAX(load_date) AS load_date,

        MAX(record_source) AS record_source

    FROM product_orders

    GROUP BY product_hk

)

SELECT
    product_hk,
    total_items_sold,
    total_product_revenue,
    total_freight_value,
    total_revenue,
    load_date,
    record_source

FROM product_metrics