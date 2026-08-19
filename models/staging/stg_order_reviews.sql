WITH source AS (

    SELECT *
    FROM {{ source('olist', 'order_reviews') }}

)

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,

    CURRENT_TIMESTAMP() AS load_date,
    'OLIST_S3' AS record_source

FROM source