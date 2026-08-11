with

    customers as (

        select
        customer_key,
        customer_id,
        first_name,
        last_name,
        kyc_status

        from {{ ref('dim_customers') }}
        where is_current

    ),

    account_counts as (

        select
        customer_id,
        count(distinct account_id) as account_count

        from {{ ref('dim_accounts') }}
        group by customer_id

    ),

    transaction_volume_90d as (

        select
        customer_id,
        sum(transaction_amount) as total_transaction_volume_90d

        from {{ ref('fct_transactions') }}
        where transaction_date >= current_date - interval '90 days'
        group by customer_id

    ),

    active_loans as (

        select
        dl.customer_id,
        count(distinct dl.loan_id) as active_loan_count

        from {{ ref('dim_loan') }} dl
        inner join {{ ref('snap_loan_status') }} sl
            on dl.loan_id = sl.loan_id
            and sl.dbt_valid_to is null
        where sl.status = 'disbursed'
        group by dl.customer_id

    ),

    -- Most recent repayment balance per loan. Loans with no repayments yet
    -- fall back to disbursed_amount in loan_outstanding below.
    latest_repayment_per_loan as (

        select
        loan_id,
        outstanding_amount_after_repayment,
        row_number() over (partition by loan_id order by repayment_date desc, created_at desc) as rn

        from {{ ref('fct_loan_repayments') }}

    ),

    loan_outstanding as (

        select
        fd.customer_id,
        coalesce(lr.outstanding_amount_after_repayment, fd.disbursed_amount) as outstanding_balance

        from {{ ref('fct_loan_disbursement') }} fd
        inner join {{ ref('snap_loan_status') }} sl
            on fd.loan_id = sl.loan_id
            and sl.dbt_valid_to is null
            and sl.status = 'disbursed'
        left join latest_repayment_per_loan lr
            on fd.loan_id = lr.loan_id
            and lr.rn = 1

    ),

    outstanding_loan_balance as (

        select
        customer_id,
        sum(outstanding_balance) as outstanding_loan_balance

        from loan_outstanding
        group by customer_id

    ),

    card_flags as (

        select distinct
        customer_id,
        true as has_debit_card

        from {{ ref('dim_cards') }}
        where card_type = 'debit'
          and status = 'active'

    )

select
    c.customer_key,
    c.customer_id,
    c.first_name,
    c.last_name,
    coalesce(ac.account_count, 0) as account_count,
    coalesce(tv.total_transaction_volume_90d, 0) as total_transaction_volume_90d,
    coalesce(al.active_loan_count, 0) as active_loan_count,
    coalesce(olb.outstanding_loan_balance, 0) as outstanding_loan_balance,
    coalesce(cf.has_debit_card, false) as has_debit_card,
    c.kyc_status as current_kyc_status

from customers c
left join account_counts ac on c.customer_id = ac.customer_id
left join transaction_volume_90d tv on c.customer_id = tv.customer_id
left join active_loans al on c.customer_id = al.customer_id
left join outstanding_loan_balance olb on c.customer_id = olb.customer_id
left join card_flags cf on c.customer_id = cf.customer_id
