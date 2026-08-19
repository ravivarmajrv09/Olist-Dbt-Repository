{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customer_hk',
    schema='BUSINESS_VAULT'
) }}

WITH customer_orders AS (

    SELECT
        l.customer_hk,
        l.order_hk,
        o.order_purchase_timestamp,
        m.total_product_value,
        m.total_freight_value,
        m.total_order_value,
        m.load_date,
        m.record_source

    FROM {{ ref('link_order_customer') }} l

    INNER JOIN {{ ref('bv_order_status') }} o
        ON l.order_hk = o.order_hk

    INNER JOIN {{ ref('bv_order_metrics') }} m
        ON l.order_hk = m.order_hk

    {% if is_incremental() %}

    WHERE m.load_date >= (
        SELECT COALESCE(
            MAX(load_date),
            '1900-01-01'::TIMESTAMP_NTZ
        )
        FROM {{ this }}
    )

    {% endif %}

),

customer_metrics AS (

    SELECT
        customer_hk,

        COUNT(DISTINCT order_hk) AS total_orders,

        SUM(total_product_value) AS total_product_spend,

        SUM(total_freight_value) AS total_freight_spend,

        SUM(total_order_value) AS total_spend,

        MAX(order_purchase_timestamp) AS last_order_date,

        MAX(load_date) AS load_date,

        MAX(record_source) AS record_source

    FROM customer_orders

    GROUP BY customer_hk

)

SELECT
    customer_hk,
    total_orders,
    total_product_spend,
    total_freight_spend,
    total_spend,
    last_order_date,
    load_date,
    record_source

FROM customer_metrics