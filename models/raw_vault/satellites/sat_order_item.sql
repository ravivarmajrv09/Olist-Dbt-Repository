{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value,
        load_date,
        record_source
    FROM {{ ref('stg_order_items') }}
    WHERE order_id IS NOT NULL
      AND order_item_id IS NOT NULL
      and product_id is not NULL
      and seller_id is not null

),

prepared AS (

    SELECT
        SHA2(
            CONCAT(
                TRIM(order_id),
                '||',
                TRIM(order_item_id::VARCHAR),
                '||',
                TRIM(product_id),
                '||',
                TRIM(seller_id)
            ),
            256
        ) AS order_item_hk,

        SHA2(
            CONCAT_WS(
                '||',
                COALESCE(TO_VARCHAR(shipping_limit_date), ''),
                COALESCE(TO_VARCHAR(price), ''),
                COALESCE(TO_VARCHAR(freight_value), '')
            ),
            256
        ) AS hashdiff,

        shipping_limit_date,
        price,
        freight_value,
        load_date,
        record_source

    FROM source_data

)

SELECT
    order_item_hk,
    hashdiff,
    shipping_limit_date,
    price,
    freight_value,
    load_date,
    record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} s
    WHERE s.order_item_hk = p.order_item_hk
      AND s.hashdiff = p.hashdiff
)

{% endif %}