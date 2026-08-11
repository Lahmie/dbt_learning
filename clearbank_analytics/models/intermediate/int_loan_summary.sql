with 
    loans as (
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

        from {{ ref('stg_raw_loans') }}
    ),

    repayments as (
        select
        loan_id,
        sum(case when status != 'reversed' then amount else 0 end) as total_repaid,
        max(case when status != 'reversed' then repayment_date end) as last_repayment_date


        from {{ ref('stg_raw_loan_repayments') }}
        group by loan_id
    ),

    intermediate as (
        select
        l.loan_id,
        l.customer_id,
        l.account_id,
        l.product_type,
        l.applied_amount,
        l.approved_amount,
        l.disbursed_amount,
        l.status as loan_status,
        l.application_date,
        l.approval_date,
        l.disbursement_date,

      
        r.total_repaid,
        r.last_repayment_date,
        l.disbursed_amount - coalesce(r.total_repaid, 0) as outstanding_amount
        


        from loans l
        left join repayments r on l.loan_id = r.loan_id
    )

    select * from intermediate