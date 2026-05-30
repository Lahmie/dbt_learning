with 
    dim_property as (
        select
        {{ dbt_utils.generate_surrogate_key(['property_id']) }} as property_key,
        p.property_id,
        p.address,
        p.type_name,
        p.category,
        p.suburb_name,
        p.postcode,
        p.state,
        p.region        
        from {{ ref('prep_properties') }} p
    )

select * from dim_property
    