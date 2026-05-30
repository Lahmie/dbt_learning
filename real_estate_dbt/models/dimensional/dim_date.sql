with 
    date_spine as (
        {{ dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2020-01-01' as date)",
            end_date="cast('2030-12-31' as date)"
        ) }}
    ),

    dim_date as (
        select
            {{ dbt_utils.generate_surrogate_key(['date_day']) }} as date_key,
            date_day,
            extract(day from date_day) as day_of_month,
            extract(month from date_day) as month_of_year,
            extract(year from date_day) as year,
            extract(quarter from date_day) as quarter,
            dayofweek(date_day) as day_of_week,
            case when dayofweek(date_day) in (1, 7) then true else false end as is_weekend
        from date_spine
    )

select * from dim_date