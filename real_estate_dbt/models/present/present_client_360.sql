-- compute full picture of client including  transactions made, total amount spent, average deal size and preferred property types. This will be used in the presentation layer to show a comprehensive view of each client's interactions with the real estate business and help identify high-value clients and their preferences.
-- note one row per transaction for each client, so we can easily aggregate and analyze client behavior and preferences in the presentation layer.

with 
    present_client_360 as (
        select 
            c.client_name,
            t.transaction_id,
            t.price,
            t.transaction_completed_time,
            t.status,
            t.is_completed,
            t.duration_days,
            p.type_name as property_type,
            a.agent_name
        from {{ ref('fct_transactions') }} t
        inner join {{ ref('dim_client') }} c on t.client_key = c.client_key
        inner join {{ ref('dim_property') }} p on t.property_key = p.property_key
        inner join {{ ref('dim_agent') }} a on t.agent_key = a.agent_key
    )


select * from present_client_360

