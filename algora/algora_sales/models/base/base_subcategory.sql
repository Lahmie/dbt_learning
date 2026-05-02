with 
    base as (
        select *
        from {{ source('transactional_data_output', 'subcategory') }}
    )

select * from base