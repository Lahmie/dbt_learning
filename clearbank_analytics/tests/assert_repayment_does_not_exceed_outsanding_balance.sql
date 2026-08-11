select 
    repayment_id,
    outstanding_amount_after_repayment + repayment_amount as new_outstanding_balance
    
from {{ ref('fct_loan_repayments') }}
where outstanding_amount_after_repayment < 0