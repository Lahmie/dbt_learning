with 
    base as (
        select 
        AGENTID as agent_id,
        AGENTNAME as agent_name,
        OFFICEID as office_id,
        LEVEL as level

        from {{ source('transactional_data', 'db_agents') }}
    )

select * from base