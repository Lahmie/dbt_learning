{% snapshot snap_customers %}

{{
    config(
        schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
    )
}}

select
    customer_id,
    first_name,
    middle_name,
    last_name,
    email,
    phone_number,
    date_of_birth,
    address,
    city,
    state,
    country,
    nationality,
    gender,
    kyc_status,
    cast(created_at as timestamp) as created_at,
    cast(updated_at as timestamp) as updated_at

from {{ ref('raw_customers') }}

{% endsnapshot %}
