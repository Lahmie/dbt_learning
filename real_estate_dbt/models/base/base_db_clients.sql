with 
    base as (
        select 
        CLIENTID as client_id,
        CLIENTNAME as client_name,
        EMAIL as email

        from {{ source('transactional_data', 'db_clients') }}
    )

select * from base