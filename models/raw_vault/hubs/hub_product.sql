{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        product_id,
        load_date,
        record_source
    FROM {{ ref('stg_products') }}
    WHERE product_id IS NOT NULL

),

prepared AS (

    SELECT DISTINCT
        SHA2(TRIM(product_id), 256) AS product_hk,
        TRIM(product_id) AS product_id,
        load_date,
        record_source
    FROM source_data

)

SELECT
    product_hk,
    product_id,
    load_date,
    record_source
FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} h
    WHERE h.product_hk = p.product_hk
)

{% endif %}