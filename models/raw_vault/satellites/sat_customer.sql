{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        load_date,
        record_source
    FROM {{ ref('stg_customers') }}
    WHERE customer_id IS NOT NULL

),

prepared AS (

    SELECT
        SHA2(TRIM(customer_id), 256) AS customer_hk,

        SHA2(
            CONCAT_WS(
                '||',
                COALESCE(TRIM(customer_unique_id), ''),
                COALESCE(TRIM(customer_zip_code_prefix), ''),
                COALESCE(TRIM(customer_city), ''),
                COALESCE(TRIM(customer_state), '')
            ),
            256
        ) AS hashdiff,

        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        load_date,
        record_source

    FROM source_data

)

SELECT
    customer_hk,
    hashdiff,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    load_date,
    record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} s
    WHERE s.customer_hk = p.customer_hk
      AND s.hashdiff = p.hashdiff
)

{% endif %}