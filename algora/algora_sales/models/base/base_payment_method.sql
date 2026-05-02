with 
    base as (
        select *
        from {{ source('transactional_data_output', 'payment_method') }}
    )

select * from base