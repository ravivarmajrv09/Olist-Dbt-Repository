{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        customer_id,
        load_date,
        record_source
    FROM {{ ref('stg_customers') }}
    WHERE customer_id IS NOT NULL

),

prepared AS (

    SELECT DISTINCT
        SHA2(TRIM(customer_id), 256) AS customer_hk,
        TRIM(customer_id) AS customer_id,
        load_date,
        record_source
    FROM source_data

)

SELECT
    customer_hk,
    customer_id,
    load_date,
    record_source
FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} h
    WHERE h.customer_hk = p.customer_hk
)

{% endif %}