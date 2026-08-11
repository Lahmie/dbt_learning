{{
    config(
        unique_key='repayment_id',
        incremental_strategy='delete+insert'
    )
}}

with

    repayments as (

        select
        repayment_id,
        loan_id,
        customer_id,
        repayment_date,
        amount,
        status,
        outstanding_amount_after_repayment,
        created_at,
        updated_at

        from {{ ref('int_loan_repayments_enriched') }}

    ),

    -- outstanding_amount_after_repayment is a running total per loan, so a status
    -- change on one repayment shifts the balance on every later repayment for that
    -- loan too. delete+insert is scoped to loan_id via changed_loans so the full
    -- repayment history for an affected loan is deleted and reinserted together,
    -- keeping the running balance consistent across all repayment_id rows.
    changed_loans as (

        select distinct loan_id
        from repayments
        {% if is_incremental() %}
        where updated_at > (select coalesce(max(updated_at), timestamp '1900-01-01') from {{ this }})
        {% endif %}

    ),

    scoped_repayments as (

        select r.*
        from repayments r
        inner join changed_loans cl on r.loan_id = cl.loan_id

    ),

    dimension_keys as (

        select
        sr.*,
        dl.loan_key,
        dc.customer_key,
        dd.date_id as repayment_date_key

        from scoped_repayments sr
        left join {{ ref('dim_loan') }} dl
            on sr.loan_id = dl.loan_id
        left join {{ ref('dim_customers') }} dc
            on sr.customer_id = dc.customer_id
            and sr.repayment_date >= cast(dc.valid_from as date)
            and (sr.repayment_date < cast(dc.valid_to as date) or dc.valid_to is null)
        left join {{ ref('dim_date') }} dd
            on sr.repayment_date = dd.date_day

    )

select
    repayment_id,
    loan_key,
    customer_key,
    repayment_date_key,
    loan_id,
    customer_id,
    repayment_date,
    amount as repayment_amount,
    status,
    outstanding_amount_after_repayment,
    created_at,
    updated_at

from dimension_keys
