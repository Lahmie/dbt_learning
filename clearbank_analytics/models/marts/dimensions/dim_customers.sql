with

    snapshots as (
        select
        customer_id,
        first_name,
        middle_name,
        last_name,
        email,
        phone_number,
        date_of_birth,
        address,
        city,
        state,
        country,
        nationality,
        gender,
        kyc_status,
        created_at,
        dbt_valid_from,
        dbt_valid_to

        from {{ ref('snap_customers') }}
    ),

    dimension as (
        select
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'dbt_valid_from']) }} as customer_key,
        customer_id,
        first_name,
        middle_name,
        last_name,
        email,
        phone_number,
        date_of_birth,
        address,
        city,
        state,
        country,
        nationality,
        gender,
        kyc_status,
        created_at,
        dbt_valid_from as valid_from,
        dbt_valid_to as valid_to,
        dbt_valid_to is null as is_current

        from snapshots
    )

select * from dimension
