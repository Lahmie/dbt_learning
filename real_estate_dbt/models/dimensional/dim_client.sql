with 
    dim_client as (
        select
        {{ dbt_utils.generate_surrogate_key(['client_id']) }} as client_key,
        c.client_id,
        c.client_name,
        c.email
        from {{ ref('prep_clients') }} c
    )
select * from dim_client