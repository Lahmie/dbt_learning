with
    source as (
        select
        repayment_id,
        loan_id,
        customer_id,
        repayment_date,
        amount,
        status,
        created_at,
        updated_at

        from {{ source('main_raw', 'raw_loan_repayments') }}
    )

select * from source
