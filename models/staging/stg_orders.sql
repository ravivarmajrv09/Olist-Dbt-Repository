WITH source AS (

    SELECT *
    FROM {{ source('olist', 'orders') }}

),

renamed AS (

    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        
        load_date,
        'OLIST' AS record_source

    FROM source

)

SELECT *
FROM renamed