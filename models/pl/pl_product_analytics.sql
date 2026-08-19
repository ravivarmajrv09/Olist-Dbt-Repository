{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='product_hk',
    schema='PL'
) }}

WITH latest_product_satellite AS (

    SELECT *
    FROM {{ ref('sat_product') }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY product_hk
        ORDER BY load_date DESC
    ) = 1

),

product_data AS (

    SELECT
        p.product_hk,
        h.product_id,

        p.total_items_sold,
        p.total_product_revenue,
        p.total_freight_value,
        p.total_revenue,

        s.product_category_name,

        p.load_date

    FROM {{ ref('bv_product_metrics') }} p

    INNER JOIN {{ ref('hub_product') }} h
        ON p.product_hk = h.product_hk

    LEFT JOIN latest_product_satellite s
        ON p.product_hk = s.product_hk

    {% if is_incremental() %}

    WHERE p.load_date >= (
        SELECT COALESCE(
            MAX(load_date),
            '1900-01-01'::TIMESTAMP_NTZ
        )
        FROM {{ this }}
    )

    {% endif %}

)

SELECT
    product_hk,
    product_id,
    product_category_name,

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

FROM product_data