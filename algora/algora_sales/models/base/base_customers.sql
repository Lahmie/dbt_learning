with 
    base as (
        select *
        from {{ source('transactional_data_output', 'customer') }}
    )

select * from base