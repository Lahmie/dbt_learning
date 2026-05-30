with 
    base as (
        select 
        STATUSID as status_id,
        STATUS as status
        from {{ source('transactional_data', 'db_status') }}
    )

select * from base