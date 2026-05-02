with 
    base as (
        select *
        from {{ source('transactional_data_output', 'orders') }}
    )

select * from base