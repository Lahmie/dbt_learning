-- Compute total transactions(count of transactions), total_revenue(sum of prices), avg_deal_size(avg price) of properties group by month joining on  region on dim_property. This will be used in the presentation layer to show trends in property prices over time and across different regions.
with 
    present_sales_overview as (
        select 
            d.year,
            d.month_of_year,
            p.region,
            count(f.transaction_key) as total_transactions,
            sum(f.price) as total_revenue,
            avg(f.price) as avg_deal_size
        from {{ ref('fct_transactions') }} f
        inner join {{ ref('dim_property') }} p on f.property_key = p.property_key
        inner join {{ ref('dim_date') }} d on date(f.transaction_completed_time) = d.date_day
        group by d.year, d.month_of_year, p.region
        order by d.year, d.month_of_year, p.region
    )

select * from present_sales_overview