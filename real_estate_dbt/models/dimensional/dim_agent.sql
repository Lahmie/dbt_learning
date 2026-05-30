with 
    dim_agent as (
        select
        {{ dbt_utils.generate_surrogate_key(['agent_id']) }} as agent_key,
        a.agent_id,
        a.agent_name,
        a.level,
        a.office_name,  
        a.address as office_address
        
        from {{ ref('prep_agents') }} a
    )
select * from dim_agent