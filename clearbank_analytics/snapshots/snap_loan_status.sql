{% snapshot snap_loan_status %}

{{
    config(
        schema='snapshots',
        unique_key='loan_id',
        strategy='timestamp',
        updated_at='updated_at',
    )
}}

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
    cast(created_at as timestamp) as created_at,
    cast(updated_at as timestamp) as updated_at

from {{ ref('raw_loans') }}

{% endsnapshot %}
