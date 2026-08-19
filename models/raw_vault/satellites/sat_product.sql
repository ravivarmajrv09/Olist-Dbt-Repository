{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        product_id,
        product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        load_date,
        record_source
    FROM {{ ref('stg_products') }}
    WHERE product_id IS NOT NULL

),

prepared AS (

    SELECT
        SHA2(TRIM(product_id), 256) AS product_hk,

        SHA2(
            CONCAT_WS(
                '||',
                COALESCE(TRIM(product_category_name), ''),
                COALESCE(TO_VARCHAR(product_name_length), ''),
                COALESCE(TO_VARCHAR(product_description_length), ''),
                COALESCE(TO_VARCHAR(product_photos_qty), ''),
                COALESCE(TO_VARCHAR(product_weight_g), ''),
                COALESCE(TO_VARCHAR(product_length_cm), ''),
                COALESCE(TO_VARCHAR(product_height_cm), ''),
                COALESCE(TO_VARCHAR(product_width_cm), '')
            ),
            256
        ) AS hashdiff,

        product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,

        load_date,
        record_source

    FROM source_data

)

SELECT
    product_hk,
    hashdiff,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    load_date,
    record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} s
    WHERE s.product_hk = p.product_hk
      AND s.hashdiff = p.hashdiff
)

{% endif %}