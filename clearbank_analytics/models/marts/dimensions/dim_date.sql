
with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2018-01-01' as date)",
        end_date="cast('2031-01-01' as date)"
    ) }}

),

dates as (

    select
        {{ dbt_utils.generate_surrogate_key(['date_day']) }} as date_id,
        cast(date_day as date)                                                                                      as date_day,
        extract(week    from cast(date_day as date))                                                                as week_number,
        extract(month   from cast(date_day as date))                                                                as month_number,
        strftime(cast(date_day as date), '%B')                                                                      as month_name,
        extract(quarter from cast(date_day as date))                                                                as quarter,
        extract(year    from cast(date_day as date))                                                                as year,
        extract(dow     from cast(date_day as date))                                                                as day_of_week,
        strftime(cast(date_day as date), '%A')                                                                      as day_name,
        extract(dow     from cast(date_day as date)) in (0, 6)                                                      as is_weekend,
        cast(date_day as date) = date_trunc('month',   cast(date_day as date))                                      as is_month_start,
        cast(date_day as date) = last_day(cast(date_day as date))                                                   as is_month_end,
        cast(date_day as date) = date_trunc('quarter', cast(date_day as date))                                      as is_quarter_start,
        cast(date_day as date) = date_trunc('quarter', cast(date_day as date)) + interval '3 months' - interval '1 day' as is_quarter_end

    from date_spine

)

select * from dates
