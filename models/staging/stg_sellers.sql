WITH source AS (

    SELECT *
    FROM {{ source('olist', 'sellers') }}

)

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,

    load_date,
    'OLIST' AS record_source

FROM source