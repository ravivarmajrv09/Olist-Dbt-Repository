{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        order_id,
        load_date,
        record_source
    FROM {{ ref('stg_orders') }}
    WHERE order_id IS NOT NULL

),

prepared AS (

    SELECT DISTINCT
        SHA2(TRIM(order_id), 256) AS order_hk,
        TRIM(order_id) AS order_id,
        load_date,
        record_source
    FROM source_data

)

SELECT
    p.order_hk,
    p.order_id,
    p.load_date,
    p.record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} h
    WHERE h.order_hk = p.order_hk
)

{% endif %}