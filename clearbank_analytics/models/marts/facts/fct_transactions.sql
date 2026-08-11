{{
    config(
        unique_key='transaction_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

with

    transactions as (

        select
        transaction_id,
        account_id,
        card_id,
        customer_id,
        transaction_date,
        amount,
        currency,
        type,
        status,
        description,
        reference_number,
        channel,
        reversal_of_transaction_id,
        transaction_created_at

        from {{ ref('int_transactions_enriched') }}

        {% if is_incremental() %}
        where transaction_created_at > (select coalesce(max(transaction_created_at), timestamp '1900-01-01') from {{ this }})
        {% endif %}

    ),

    dimension_keys as (

        select
        t.*,
        da.account_key,
        dc.customer_key,
        dcard.card_key,
        dd.date_id as transaction_date_key

        from transactions t
        left join {{ ref('dim_accounts') }} da
            on t.account_id = da.account_id
        left join {{ ref('dim_customers') }} dc
            on t.customer_id = dc.customer_id
            and t.transaction_date >= dc.valid_from
            and (t.transaction_date < dc.valid_to or dc.valid_to is null)
        left join {{ ref('dim_date') }} dd
            on cast(t.transaction_date as date) = dd.date_day
        left join {{ ref('dim_cards') }} dcard
            on t.card_id = dcard.card_id

    ),

    -- Carries the last posted balance per account into this batch so running_balance
    -- doesn't need to be recomputed over full history on every incremental run.
    prior_balance as (

        {% if is_incremental() %}
        select
        account_id,
        max(running_balance) as starting_balance
        from {{ this }}
        group by account_id
        {% else %}
        select
        account_id,
        cast(null as double) as starting_balance
        from {{ ref('int_transactions_enriched') }}
        where false
        {% endif %}

    ),

    with_running_balance as (

        select
        dk.*,
        coalesce(pb.starting_balance, 0)
            + sum(dk.amount) over (
                partition by dk.account_id
                order by dk.transaction_date, dk.transaction_id
                rows unbounded preceding
              ) as running_balance,
        dk.reversal_of_transaction_id is not null as is_reversal

        from dimension_keys dk
        left join prior_balance pb on dk.account_id = pb.account_id

    )

select
    transaction_id,
    transaction_date_key,
    account_key,
    customer_key,
    card_key,
    account_id,
    customer_id,
    card_id,
    transaction_date,
    amount as transaction_amount,
    currency,
    type as transaction_type,
    status,
    description,
    reference_number,
    channel,
    reversal_of_transaction_id,
    is_reversal,
    running_balance,
    transaction_created_at

from with_running_balance
