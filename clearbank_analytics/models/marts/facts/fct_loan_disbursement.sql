{{
    config(
        unique_key='loan_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

with

    loans as (

        select
        loan_id,
        customer_id,
        account_id,
        product_type,
        approved_amount,
        disbursed_amount,
        disbursement_date,
        updated_at

        from {{ ref('stg_raw_loans') }}
        where disbursement_date is not null

        {% if is_incremental() %}
        and updated_at > (select coalesce(max(updated_at), timestamp '1900-01-01') from {{ this }})
        {% endif %}

    ),

    dimension_keys as (

        select
        l.*,
        da.account_key,
        dl.loan_key,
        dc.customer_key,
        dd.date_id as disbursement_date_key

        from loans l
        left join {{ ref('dim_accounts') }} da
            on l.account_id = da.account_id
        left join {{ ref('dim_loan') }} dl
            on l.loan_id = dl.loan_id
        left join {{ ref('dim_customers') }} dc
            on l.customer_id = dc.customer_id
            and l.disbursement_date >= cast(dc.valid_from as date)
            and (l.disbursement_date < cast(dc.valid_to as date) or dc.valid_to is null)
        left join {{ ref('dim_date') }} dd
            on l.disbursement_date = dd.date_day

    )

select
    loan_id,
    loan_key,
    customer_key,
    account_key,
    disbursement_date_key,
    customer_id,
    account_id,
    product_type,
    approved_amount,
    disbursed_amount,
    disbursement_date,
    updated_at

from dimension_keys
