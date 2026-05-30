with 
    base as (
        select 
        TXNID as transaction_id,
        PROPERTYID as property_id,
        AGENTID as agent_id,
        CLIENTID as client_id,
        STATUSID as status_id,
        CAST(PRICE as FLOAT) as price,
        TO_TIMESTAMP(ACCM_TXN_CREATE_TIME, 'MM/DD/YYYY HH24:MI') as transaction_created_time,
        TO_TIMESTAMP(ACCM_TXN_COMPLETE_TIME, 'MM/DD/YYYY HH24:MI') as transaction_completed_time
        from {{ source('transactional_data', 'db_transactions') }}
    )

select * from base