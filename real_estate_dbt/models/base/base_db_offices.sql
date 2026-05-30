with 
    base as (
        select 
        OFFICEID as office_id,
        OFFICENAME as office_name,
        ADDRESS as address,
        from {{ source('transactional_data', 'db_offices') }}
    )

select * from base