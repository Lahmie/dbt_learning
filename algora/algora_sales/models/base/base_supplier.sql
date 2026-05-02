with 
    base as (
        select *
        from {{ source('transactional_data_output', 'supplier') }}
    )

select * from base