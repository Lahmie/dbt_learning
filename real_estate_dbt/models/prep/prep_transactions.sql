with 
    transactions as (
        select 
        t.transaction_id,
         t.property_id,
         t.agent_id,
         t.client_id,
         t.status_id,
         t.price,
         t.transaction_created_time,
         t.transaction_completed_time
        from {{ ref('base_db_transactions') }} t
    ),

    properties as (
        select 
        p.property_id,
        p.address,
        p.type_name,
        p.category,
        p.suburb_name,
        p.postcode,
        p.state,
        p.region
        from {{ ref('prep_properties') }} p
    ),


    clients as (
        select 
        c.client_id,
        c.client_name,
        c.email as client_email
        from {{ ref('base_db_clients') }} c
    ),

    agents as (
        select 
        a.agent_id,
        a.agent_name,
        a.level,
        a.office_name,
        a.address as agents_office_address
        from {{ ref('prep_agents') }} a
    ),

    transaction_status as (
        select 
        s.status_id,
        s.status
        from {{ ref('base_db_status') }} s
    ),



    prep as (
        select 
        t.transaction_id,
        p.property_id,
        a.agent_id,
        c.client_id,
        s.status_id,
        p.type_name,
        p.category,
        p.suburb_name,
        p.postcode,
        p.state,
        p.region,
        p.address,
        a.agent_name,
        a.level,
        a.office_name,
        a.agents_office_address,
        c.client_name,
        c.client_email,
        s.status,
        t.price,
        t.transaction_created_time,
        t.transaction_completed_time,
        DATEDIFF('day', t.transaction_created_time, t.transaction_completed_time) as duration_days,
        CASE WHEN transaction_completed_time IS NOT NULL THEN TRUE ELSE FALSE END as is_completed

        from transactions t
        inner join properties p on t.property_id = p.property_id
        inner join agents a on t.agent_id = a.agent_id
        inner join clients c on t.client_id = c.client_id
        inner join transaction_status s on t.status_id = s.status_id
    )

select * from prep