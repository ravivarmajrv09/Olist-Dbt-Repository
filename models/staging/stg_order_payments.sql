WITH source AS (

    SELECT *
    FROM {{ source('olist', 'order_payments') }}

)

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,

    CURRENT_TIMESTAMP() AS load_date,
    'OLIST_S3' AS record_source

FROM source