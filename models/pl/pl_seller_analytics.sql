{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='seller_hk',
    schema='PL'
) }}

WITH latest_seller_satellite AS (

    SELECT *
    FROM {{ ref('sat_seller') }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY seller_hk
        ORDER BY load_date DESC
    ) = 1

),

seller_data AS (

    SELECT
        s.seller_hk,
        h.seller_id,

        s.total_items_sold,
        s.total_product_revenue,
        s.total_freight_value,
        s.total_revenue,

        sat.seller_city,
        sat.seller_state,

        s.load_date

    FROM {{ ref('bv_seller_metrics') }} s

    INNER JOIN {{ ref('hub_seller') }} h
        ON s.seller_hk = h.seller_hk

    LEFT JOIN latest_seller_satellite sat
        ON s.seller_hk = sat.seller_hk

    {% if is_incremental() %}

    WHERE s.load_date >= (
        SELECT COALESCE(
            MAX(load_date),
            '1900-01-01'::TIMESTAMP_NTZ
        )
        FROM {{ this }}
    )

    {% endif %}

)

SELECT
    seller_hk,
    seller_id,

    seller_city,
    seller_state,

    total_items_sold,
    total_product_revenue,
    total_freight_value,
    total_revenue,

    CASE
        WHEN total_items_sold > 0
        THEN total_product_revenue / total_items_sold
        ELSE 0
    END AS average_item_price,

    load_date,
    CURRENT_TIMESTAMP() AS pl_load_date

FROM seller_data