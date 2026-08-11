with

    loans as (

        select
        dl.loan_key,
        dl.loan_id,
        dl.customer_id,
        dl.applied_amount as original_amount,
        fd.disbursed_amount,
        sl.status as loan_status,
        fd.disbursement_date

        from {{ ref('dim_loan') }} dl
        inner join {{ ref('fct_loan_disbursement') }} fd
            on dl.loan_id = fd.loan_id
        left join {{ ref('snap_loan_status') }} sl
            on dl.loan_id = sl.loan_id
            and sl.dbt_valid_to is null

    ),

    repayments_agg as (

        select
        loan_id,
        sum(case when status = 'successful' then repayment_amount else 0 end) as total_repaid_to_date,
        max(repayment_date) as last_repayment_date

        from {{ ref('fct_loan_repayments') }}
        group by loan_id

    ),

    latest_outstanding as (

        select
        loan_id,
        outstanding_amount_after_repayment,
        row_number() over (partition by loan_id order by repayment_date desc, created_at desc) as rn

        from {{ ref('fct_loan_repayments') }}

    ),

    health as (

        select
        l.loan_key,
        l.loan_id,
        l.customer_id,
        l.original_amount,
        l.disbursed_amount,
        l.loan_status,
        l.disbursement_date,
        coalesce(ra.total_repaid_to_date, 0) as total_repaid_to_date,
        coalesce(lo.outstanding_amount_after_repayment, l.disbursed_amount) as outstanding_balance,
        ra.last_repayment_date,

        -- No repayment yet: clock starts from disbursement_date instead
        coalesce(
            datediff('day', ra.last_repayment_date, current_date),
            datediff('day', l.disbursement_date, current_date)
        ) as days_since_last_repayment

        from loans l
        left join repayments_agg ra on l.loan_id = ra.loan_id
        left join latest_outstanding lo
            on l.loan_id = lo.loan_id
            and lo.rn = 1

    )

select
    loan_key,
    loan_id,
    customer_id,
    original_amount,
    disbursed_amount,
    disbursement_date,
    loan_status,
    total_repaid_to_date,
    outstanding_balance,
    last_repayment_date,
    days_since_last_repayment,
    case
        when loan_status = 'defaulted' then 'defaulted'
        when days_since_last_repayment > 90 then 'defaulted'
        when days_since_last_repayment > 30 then 'at_risk'
        else 'on_track'
    end as loan_health_flag

from health
