with 
    fct_transactions as (
    select
        {{dbt_utils.generate_surrogate_key(['transaction_id'])}} as transaction_key,
        t.transaction_id,
        p.property_key,
        a.agent_key,
        c.client_key,
        t.price,
        t.transaction_created_time,
        t.transaction_completed_time,
        t.duration_days,
        t.status,
        t.is_completed
    from {{ ref('prep_transactions') }} t
    inner join {{ ref('dim_property') }} p on t.property_id = p.property_id
    inner join {{ ref('dim_agent') }} a on t.agent_id = a.agent_id
    inner join {{ ref('dim_client') }} c on t.client_id = c.client_id
)

select * from fct_transactions