with 
    base as (
        select 
        TYPECODE AS type_code,
        TYPENAME AS type_name,
        CATEGORY AS category
        from {{ source('transactional_data', 'property_types') }}
    )

select * from base