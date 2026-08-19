{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value,
        load_date,
        record_source
    FROM {{ ref('stg_order_payments') }}
    WHERE order_id IS NOT NULL

),

prepared AS (

    SELECT
        SHA2(
            CONCAT(
                TRIM(order_id),
                '||',
                TRIM(payment_sequential::VARCHAR)
            ),
            256
        ) AS order_payment_hk,

        SHA2(
            CONCAT_WS(
                '||',
                COALESCE(TRIM(payment_type), ''),
                COALESCE(TO_VARCHAR(payment_installments), ''),
                COALESCE(TO_VARCHAR(payment_value), '')
            ),
            256
        ) AS hashdiff,

        payment_type,
        payment_installments,
        payment_value,
        load_date,
        record_source

    FROM source_data

)

SELECT
    order_payment_hk,
    hashdiff,
    payment_type,
    payment_installments,
    payment_value,
    load_date,
    record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} s
    WHERE s.order_payment_hk = p.order_payment_hk
      AND s.hashdiff = p.hashdiff
)

{% endif %}