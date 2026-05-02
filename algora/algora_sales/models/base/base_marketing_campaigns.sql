with 
    base as (
        select *
        from {{ source('transactional_data_output', 'marketing_campaigns') }}
    )

select * from base