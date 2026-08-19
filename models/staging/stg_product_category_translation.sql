WITH source AS (

    SELECT *
    FROM {{ source('olist', 'product_category_translation') }}

)

SELECT
    product_category_name,
    product_category_name_english,

    CURRENT_TIMESTAMP() AS load_date,
    'OLIST_S3' AS record_source

FROM source