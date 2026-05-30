with 
    base as (
        select 
        SUBURBID AS suburb_id,
        SUBURBNAME AS suburb_name,
        POSTCODE AS postcode,
        STATE AS state,
        REGION AS region

        from {{ source('transactional_data', 'location_hierarchy') }}
    )

select * from base