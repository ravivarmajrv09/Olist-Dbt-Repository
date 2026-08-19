{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customer_hk',
    schema='PL'
) }}

WITH customer_data AS (

    SELECT
        c.customer_hk,
        h.customer_id,
        c.total_orders,
        c.total_product_spend,
        c.total_freight_spend,
        c.total_spend,
        c.last_order_date,
        c.load_date

    FROM {{ ref('bv_customer_metrics') }} c

    INNER JOIN {{ ref('hub_customer') }} h
        ON c.customer_hk = h.customer_hk

    {% if is_incremental() %}

    WHERE c.load_date >= (
        SELECT COALESCE(
            MAX(load_date),
            '1900-01-01'::TIMESTAMP_NTZ
        )
        FROM {{ this }}
    )

    {% endif %}

)

SELECT
    customer_hk,
    customer_id,

    total_orders,
    total_product_spend,
    total_freight_spend,
    total_spend,

    CASE
        WHEN total_orders > 0
        THEN total_spend / total_orders
        ELSE 0
    END AS average_order_value,

    last_order_date,

    load_date,
    CURRENT_TIMESTAMP() AS pl_load_date

FROM customer_data