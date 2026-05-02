with 
    base as (
        select *
        from {{ source('transactional_data_output', 'campaign_product_subcategory') }}
    )

select * from base