WITH source AS (

    SELECT *
    FROM {{ source('olist', 'order_items') }}

)

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,

    CURRENT_TIMESTAMP() AS load_date,
    'OLIST_S3' AS record_source

FROM source