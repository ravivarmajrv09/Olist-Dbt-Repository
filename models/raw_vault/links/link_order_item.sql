{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT DISTINCT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        load_date,
        record_source
    FROM {{ ref('stg_order_items') }}
    WHERE order_id IS NOT NULL
      AND product_id IS NOT NULL
      AND seller_id IS NOT NULL

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

        SHA2(TRIM(order_id), 256) AS order_hk,

        SHA2(TRIM(product_id), 256) AS product_hk,

        SHA2(TRIM(seller_id), 256) AS seller_hk,

        order_item_id,

        load_date,
        record_source

    FROM source_data

)

SELECT
    order_item_hk,
    order_hk,
    product_hk,
    seller_hk,
    order_item_id,
    load_date,
    record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} l
    WHERE l.order_item_hk = p.order_item_hk
)

{% endif %}