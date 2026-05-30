with 
    prep as (
        select 
        c.client_id,
        c.client_name,
        c.email
        from {{ ref('base_db_clients') }} c
    )
select * from prep