{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT DISTINCT
        order_id,
        customer_id,
        load_date,
        record_source
    FROM {{ ref('stg_orders') }}
    WHERE order_id IS NOT NULL
      AND customer_id IS NOT NULL

),

prepared AS (

    SELECT
        SHA2(
            CONCAT(
                TRIM(order_id),
                '||',
                TRIM(customer_id)
            ),
            256
        ) AS order_customer_hk,

        SHA2(TRIM(order_id), 256) AS order_hk,

        SHA2(TRIM(customer_id), 256) AS customer_hk,

        load_date,
        record_source

    FROM source_data

)

SELECT
    order_customer_hk,
    order_hk,
    customer_hk,
    load_date,
    record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} l
    WHERE l.order_customer_hk = p.order_customer_hk
)

{% endif %}