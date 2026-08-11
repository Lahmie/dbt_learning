with
    source as (
        select
        transaction_id,
        account_id,
        card_id,
        transaction_date,
        amount,
        currency,
        type,
        status,
        description,
        reference_number,
        channel,
        reversal_of_transaction_id,
        created_at

        from {{ source('main_raw', 'raw_transactions') }}
    )

select * from source
