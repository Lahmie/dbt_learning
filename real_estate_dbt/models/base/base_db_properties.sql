with 
    base as (
        select 
        PROPERTYID as property_id,
        ADDRESS as address,
        SUBURBID as suburb_id,
        TYPECODE as type_code
        from {{ source('transactional_data', 'db_properties') }}
    )

select * from base