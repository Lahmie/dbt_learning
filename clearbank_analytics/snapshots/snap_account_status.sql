{% snapshot snap_account_status %}

{{
    config(
        schema='snapshots',
        unique_key='account_id',
        strategy='timestamp',
        updated_at='updated_at',
    )
}}

select
    account_id,
    account_number,
    customer_id,
    account_type,
    currency,
    status,
    opened_date,
    closed_date,
    cast(created_at as timestamp) as created_at,
    cast(updated_at as timestamp) as updated_at

from {{ ref('raw_accounts') }}

{% endsnapshot %}
