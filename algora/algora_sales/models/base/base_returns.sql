with 
    base as (
        select *
        from {{ source('transactional_data_output', 'returns') }}
    )

select * from base    