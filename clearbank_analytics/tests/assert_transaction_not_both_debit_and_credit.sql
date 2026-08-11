select
    transaction_id,
    transaction_amount,
    is_reversal
from {{ ref('fct_transactions') }}
where is_reversal = true
and transaction_amount > 0