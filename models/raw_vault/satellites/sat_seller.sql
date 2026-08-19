{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        load_date,
        record_source
    FROM {{ ref('stg_sellers') }}
    WHERE seller_id IS NOT NULL

),

prepared AS (

    SELECT
        SHA2(TRIM(seller_id), 256) AS seller_hk,

        SHA2(
            CONCAT_WS(
                '||',
                COALESCE(TRIM(seller_zip_code_prefix), ''),
                COALESCE(TRIM(seller_city), ''),
                COALESCE(TRIM(seller_state), '')
            ),
            256
        ) AS hashdiff,

        seller_zip_code_prefix,
        seller_city,
        seller_state,

        load_date,
        record_source

    FROM source_data

)

SELECT
    seller_hk,
    hashdiff,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    load_date,
    record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} s
    WHERE s.seller_hk = p.seller_hk
      AND s.hashdiff = p.hashdiff
)

{% endif %}