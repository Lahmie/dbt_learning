with 
    transactions as (
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

        from {{ ref('stg_raw_transactions') }}
    ),

    accounts as (
        select
        account_id,
        customer_id

        from {{ ref('stg_raw_accounts') }}
    ),

    intermediate as (
        select
        t.transaction_id,
        t.account_id,
        t.card_id,
        a.customer_id,
        t.transaction_date,
        t.amount,
        t.currency,
        t.type,
        t.status,
        t.description,
        t.reference_number,
        t.channel,
        t.reversal_of_transaction_id,
        t.created_at as transaction_created_at


        from transactions t
        left join accounts a on t.account_id = a.account_id
    )

select * from intermediate