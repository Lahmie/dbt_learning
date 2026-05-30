-- compute average price per property type, location and time period. This will be used in the presentation layer to show trends in property prices over time and across different regions and property types.

with 
    present_property_insights as (
        select 
            p.type_name,
            p.region,
            date_trunc('month', f.transaction_completed_time) as transaction_month,
            avg(f.price) as avg_price
        from {{ ref('fct_transactions') }} f
        inner join {{ ref('dim_property') }} p on f.property_key = p.property_key
        where f.is_completed = true
        group by p.type_name, p.region, date_trunc('month', f.transaction_completed_time)
        order by transaction_month, p.region, p.type_name
    )
select * from present_property_insights