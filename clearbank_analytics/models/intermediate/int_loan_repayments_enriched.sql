with 
    loan_repayments as (
        select
        repayment_id,
        loan_id,
        customer_id,
        repayment_date,
        amount,
        status,
        created_at,
        updated_at

        from {{ ref('stg_raw_loan_repayments') }}
        where status != 'reversed' -- we exclude reversed repayments as they do not represent actual repayments that reduce the outstanding loan amount. Reversed repayments are essentially cancelled transactions and should not be included in the calculation of the outstanding amount after each repayment event.
    ),

    loan_details as (
        select 
        loan_id,
        disbursed_amount

        from {{ ref('stg_raw_loans') }}
    ),

    intermediate as (
        select
        lr.repayment_id,
        lr.loan_id,
        lr.customer_id,
        lr.repayment_date,
        lr.amount,
        lr.status,
        lr.created_at,
        lr.updated_at,
        ld.disbursed_amount,
        --outstanding_amount_after_repayment is calculated as the difference between the cumulative repayemts up to and including each repayment event and the disbursed amount. This is a running total of the outstanding amount after each repayment event.
        ld.disbursed_amount - sum(lr.amount) over (partition by lr.loan_id order by lr.repayment_date, lr.created_at) as outstanding_amount_after_repayment
    

        from loan_repayments lr
        left join loan_details ld on lr.loan_id = ld.loan_id
    )

select * from intermediate