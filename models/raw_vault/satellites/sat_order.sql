{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        order_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        load_date,
        record_source
    FROM {{ ref('stg_orders') }}
    WHERE order_id IS NOT NULL

),

prepared AS (

    SELECT
        SHA2(TRIM(order_id), 256) AS order_hk,

        SHA2(
            CONCAT_WS(
                '||',
                COALESCE(order_status, ''),
                COALESCE(TO_VARCHAR(order_purchase_timestamp), ''),
                COALESCE(TO_VARCHAR(order_approved_at), ''),
                COALESCE(TO_VARCHAR(order_delivered_carrier_date), ''),
                COALESCE(TO_VARCHAR(order_delivered_customer_date), ''),
                COALESCE(TO_VARCHAR(order_estimated_delivery_date), '')
            ),
            256
        ) AS hashdiff,

        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,

        load_date,
        record_source

    FROM source_data

)

SELECT
    order_hk,
    hashdiff,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    load_date,
    record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} s
    WHERE s.order_hk = p.order_hk
      AND s.hashdiff = p.hashdiff
)

{% endif %}