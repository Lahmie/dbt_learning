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

        from {{ ref('stg_raw_cards') }}
    ),

    dimension as (
        select
        {{ dbt_utils.generate_surrogate_key(['card_id']) }} as card_key,
        card_id,
        account_id,
        customer_id,
        card_type,
        status,
        issued_date,
        expiry_date,
        created_at,
        updated_at

        from source
    )

select * from dimension
