with
    source as (
        select
        card_id,
        account_id,
        customer_id,
        card_type,
        status,
        issued_date,
        expiry_date,
        created_at,
        updated_at

        from {{ source('main_raw', 'raw_cards') }}
    )

select * from source
