with
    agents as (
        select 
        a.agent_id,
        a.agent_name,
        a.office_id,
        a.level

        from {{ ref('base_db_agents') }} a
       
    ),
    
    offices as (
        select 
        o.office_id,
        o.office_name,
        o.address

        from {{ ref('base_db_offices') }} o
    ),


    prep as (
        select 
        a.agent_id,
        a.agent_name,
        a.level,
        o.office_name,
        o.address

        from agents a
        inner join offices o on a.office_id = o.office_id
    )

select * from prep