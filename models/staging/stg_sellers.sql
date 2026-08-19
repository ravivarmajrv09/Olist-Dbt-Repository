WITH source AS (

    SELECT *
    FROM {{ source('olist', 'sellers') }}

)

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,

    CURRENT_TIMESTAMP() AS load_date,
    'OLIST_S3' AS record_source

FROM source