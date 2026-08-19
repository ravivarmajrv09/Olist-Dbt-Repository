{{ config(
    materialized='incremental',
    incremental_strategy='append',
    schema='RAW_VAULT'
) }}

WITH source_data AS (

    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        load_date,
        record_source
    FROM {{ ref('stg_order_reviews') }}
    WHERE review_id IS NOT NULL
      AND order_id IS NOT NULL

),

prepared AS (

    SELECT
        SHA2(
            CONCAT(
                TRIM(order_id),
                '||',
                TRIM(review_id)
            ),
            256
        ) AS order_review_hk,

        SHA2(
            CONCAT_WS(
                '||',
                COALESCE(TO_VARCHAR(review_score), ''),
                COALESCE(TRIM(review_comment_title), ''),
                COALESCE(TRIM(review_comment_message), ''),
                COALESCE(TO_VARCHAR(review_creation_date), ''),
                COALESCE(TO_VARCHAR(review_answer_timestamp), '')
            ),
            256
        ) AS hashdiff,

        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        load_date,
        record_source

    FROM source_data

)

SELECT
    order_review_hk,
    hashdiff,
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    load_date,
    record_source

FROM prepared p

{% if is_incremental() %}

WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} s
    WHERE s.order_review_hk = p.order_review_hk
      AND s.hashdiff = p.hashdiff
)

{% endif %}