{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='order_hk',
    schema='BUSINESS_VAULT'
) }}

WITH order_items AS (

    SELECT
        l.order_hk,
        s.order_item_hk,
        s.price,
        s.freight_value,
        s.load_date,
        s.record_source

    FROM {{ ref('link_order_item') }} l

    INNER JOIN {{ ref('sat_order_item') }} s
        ON l.order_item_hk = s.order_item_hk

    {% if is_incremental() %}

    WHERE s.load_date >= (
        SELECT COALESCE(
            MAX(load_date),
            '1900-01-01'::TIMESTAMP_NTZ
        )
        FROM {{ this }}
    )

    {% endif %}

),

aggregated AS (

    SELECT
        order_hk,

        COUNT(DISTINCT order_item_hk) AS item_count,

        SUM(price) AS total_product_value,

        SUM(freight_value) AS total_freight_value,

        SUM(price + freight_value) AS total_order_value,

        MAX(load_date) AS load_date,

        MAX(record_source) AS record_source

    FROM order_items

    GROUP BY order_hk

)

SELECT
    order_hk,
    item_count,
    total_product_value,
    total_freight_value,
    total_order_value,
    load_date,
    record_source

FROM aggregated