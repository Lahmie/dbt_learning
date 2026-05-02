with 
    base as (
        select *
        from {{ source('transactional_data_output', 'category') }}
    )

select * from base