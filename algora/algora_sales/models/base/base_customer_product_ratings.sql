with 
    base as (
        select *
        from {{ source('transactional_data_output', 'customer_product_ratings') }}
    )

select * from base