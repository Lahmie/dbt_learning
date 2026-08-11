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
        status,
        application_date,
        approval_date,
        disbursement_date,
        created_at,
        updated_at

        from {{ source('main_raw', 'raw_loans') }}
    )

select * from source
