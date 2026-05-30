-- compute each agent performance by calculating no of deals closed, total revenue generated, duration of deals closed and average deal size. This will be used in the presentation layer to show the performance of each agent and identify top performers.

with 
    present_agent_performance as (
        select 
            a.agent_name,
            count(f.transaction_key) as total_deals_closed,
            sum(f.price) as total_revenue_generated,
            avg(f.duration_days) as avg_duration_of_deals_closed,
            avg(f.price) as avg_deal_size
        from {{ ref('fct_transactions') }} f
        inner join {{ ref('dim_agent') }} a on f.agent_key = a.agent_key
        where f.is_completed = true
        group by a.agent_name
        order by total_revenue_generated desc
    )
select * from present_agent_performance