WITH source AS (

    SELECT *
    FROM {{ source('olist', 'product_category_translation') }}

)

SELECT
    product_category_name,
    product_category_name_english,

    load_date,
    'OLIST' AS record_source

FROM source