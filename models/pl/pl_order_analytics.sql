{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='order_hk',
    schema='PL'
) }}

WITH order_data AS (

    SELECT
        s.order_hk,
        s.order_id,
        s.order_status,
        s.business_order_status,
        s.delivery_performance,

        s.order_purchase_timestamp,
        s.order_approved_at,
        s.order_delivered_carrier_date,
        s.order_delivered_customer_date,
        s.order_estimated_delivery_date,

        COALESCE(m.item_count, 0) AS item_count,

        COALESCE(
            m.total_product_value,
            0
        ) AS total_product_value,

        COALESCE(
            m.total_freight_value,
            0
        ) AS total_freight_value,

        COALESCE(
            m.total_order_value,
            0
        ) AS total_order_value,

        s.load_date

    FROM {{ ref('bv_order_status') }} s

    LEFT JOIN {{ ref('bv_order_metrics') }} m
        ON s.order_hk = m.order_hk

    {% if is_incremental() %}

    WHERE GREATEST(
        s.load_date,
        COALESCE(
            m.load_date,
            s.load_date
        )
    ) >= (
        SELECT COALESCE(
            MAX(load_date),
            '1900-01-01'::TIMESTAMP_NTZ
        )
        FROM {{ this }}
    )

    {% endif %}

)

SELECT
    order_hk,
    order_id,

    order_status,
    business_order_status,
    delivery_performance,

    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    item_count,
    total_product_value,
    total_freight_value,
    total_order_value,

    CASE
        WHEN total_order_value > 0
        THEN total_freight_value / total_order_value
        ELSE 0
    END AS freight_percentage,

    load_date,

    CURRENT_TIMESTAMP() AS pl_load_date

FROM order_data