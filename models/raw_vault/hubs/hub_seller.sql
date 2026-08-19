{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        seller_id,
        load_date,
        record_source
    FROM {{ ref('stg_sellers') }}
    WHERE seller_id IS NOT NULL

),

prepared AS (

    SELECT DISTINCT
        SHA2(TRIM(seller_id), 256) AS seller_hk,
        TRIM(seller_id) AS seller_id,
        load_date,
        record_source
    FROM source_data

)

SELECT
    seller_hk,
    seller_id,
    load_date,
    record_source
FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} h
    WHERE h.seller_hk = p.seller_hk
)

{% endif %}