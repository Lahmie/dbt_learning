with 
    base as (
        select *
        from {{ source('transactional_data_output', 'product') }}
    )

select * from base      