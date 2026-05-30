-- join base_db_properties with base_property_type on type_code and base_location_hierarchy on suburb_id

with 
    properties as (
        select 
        p.property_id,
        p.address,
        p.suburb_id,
        p.type_code
        from {{ ref('base_db_properties') }} p
    ),

    property_types as (
        select
        pt.type_code,
        pt.type_name,
        pt.category
        from {{ ref('base_property_types') }} pt
    ),

    location_hierarchy as (
        select
        lh.suburb_id,
        lh.suburb_name,
        lh.postcode,
        lh.state,
        lh.region
        from {{ ref('base_location_hierarchy') }} lh
    ),


    prep as (
        select 
        p.property_id,
        p.address,
        pt.type_name,
        pt.category,
        lh.suburb_name,
        lh.postcode,
        lh.state,
        lh.region

        from properties p
        inner join property_types pt on p.type_code = pt.type_code
        inner join location_hierarchy lh on p.suburb_id = lh.suburb_id
    )

select * from prep
