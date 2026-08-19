{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='order_hk',
    schema='BUSINESS_VAULT'
) }}

WITH orders AS (

    SELECT
        h.order_hk,
        h.order_id,
        s.order_status,
        s.order_purchase_timestamp,
        s.order_approved_at,
        s.order_delivered_carrier_date,
        s.order_delivered_customer_date,
        s.order_estimated_delivery_date,
        s.load_date,
        s.record_source

    FROM {{ ref('hub_order') }} h

    INNER JOIN {{ ref('sat_order') }} s
        ON h.order_hk = s.order_hk

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

business_rules AS (

    SELECT
        order_hk,
        order_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,

        CASE
            WHEN order_status = 'delivered'
                 AND order_delivered_customer_date IS NOT NULL
                THEN 'COMPLETED'

            WHEN order_status = 'canceled'
                THEN 'CANCELLED'

            WHEN order_status IN (
                'created',
                'approved',
                'processing',
                'shipped',
                'invoiced'
            )
                THEN 'IN_PROGRESS'

            ELSE 'OTHER'
        END AS business_order_status,

        CASE
            WHEN order_delivered_customer_date IS NOT NULL
             AND order_estimated_delivery_date IS NOT NULL
             AND order_delivered_customer_date
                 <= order_estimated_delivery_date
                THEN 'ON_TIME'

            WHEN order_delivered_customer_date IS NOT NULL
             AND order_estimated_delivery_date IS NOT NULL
             AND order_delivered_customer_date
                 > order_estimated_delivery_date
                THEN 'LATE'

            ELSE 'NOT_DELIVERED'
        END AS delivery_performance,

        load_date,
        record_source

    FROM orders

)

SELECT *
FROM business_rules