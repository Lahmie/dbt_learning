with

    source as (
        select
        loan_id,
        customer_id,
        account_id,
        product_type,
        applied_amount,
        approved_amount,
        disbursed_amount,
        application_date,
        approval_date,
        disbursement_date,
        created_at,
        updated_at

        from {{ ref('stg_raw_loans') }}
    ),

    dimension as (
        select
        {{ dbt_utils.generate_surrogate_key(['loan_id']) }} as loan_key,
        loan_id,
        customer_id,
        account_id,
        product_type,
        applied_amount,
        approved_amount,
        disbursed_amount,
        application_date,
        approval_date,
        disbursement_date,
        created_at,
        updated_at

        from source
    )

select * from dimension
