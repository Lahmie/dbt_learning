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

        from {{ source('main_raw', 'raw_accounts') }}
    )

select * from source
