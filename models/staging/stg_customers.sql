WITH source AS (

    SELECT *
    FROM {{ source('olist', 'customers') }}

)

SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,

    load_date,
    'OLIST' AS record_source

FROM source