with 
    base as (
        select *
        from {{ source('transactional_data_output', 'orderitem') }}
    )

select * from base