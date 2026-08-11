with

    source as (
        select
        account_id,
        account_number,
        customer_id,
        account_type,
        currency,
        status,
        opened_date,
        closed_date,
        created_at,
        updated_at

        from {{ ref('stg_raw_accounts') }}
    ),

    dimension as (
        select
        {{ dbt_utils.generate_surrogate_key(['account_id']) }} as account_key,
        account_id,
        account_number,
        customer_id,
        account_type,
        currency,
        status,
        opened_date,
        closed_date,
        created_at,
        updated_at

        from source
    )

select * from dimension
