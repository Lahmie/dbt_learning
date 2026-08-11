# Assumptions

## Dimensional Design

### Business processes and grain

Three business processes were identified, each backed by its own incremental fact table:

- **Money moving through accounts** — `fct_transactions`. *One row in `fct_transactions`
  represents one transaction event on one account on one date.*
- **Loan repayment activity** — `fct_loan_repayments`. *One row in `fct_loan_repayments`
  represents one repayment event against one loan.*
- **Loan disbursement** — `fct_loan_disbursement`. *One row in `fct_loan_disbursement`
  represents one disbursement event against one approved loan.*

The third fact table (disbursement) wasn't in the original two-process brief but was
added because disbursement is a distinct, measurable event (amount, date) separate
from a loan's repayment schedule, and both `mart_loan_health` and `mart_customer_360`
need a clean "this loan was disbursed on this date for this amount" fact rather than
inferring it from `dim_loan` attributes.

### SCD type decisions

- **`dim_customers` — Type 2.** Regulatory KYC requirements need a full audit trail of
  customer detail changes (address, contact info, KYC status), so history must be
  retained. Backed by the `snap_customers` snapshot (`timestamp` strategy on
  `updated_at`). Conformed across all three fact tables — every fact resolves the
  customer key as-of the fact's own event date (`transaction_date`, `repayment_date`,
  `disbursement_date`), not just the current customer version.
- **`dim_accounts` — Type 1.** Reporting only ever needs an account's current
  attributes (type, currency, status); nothing in the mart layer asks "what was this
  account's status on date X". Built as a plain overwrite-on-each-run table directly
  from staging. Full status history is still captured independently in
  `snap_account_status`, available if a future model needs an as-of view.
- **`dim_loan` — Type 1, and `status` deliberately excluded.** Loan terms (amounts,
  product type, application date) are fixed at origination and never change, which is
  what makes Type 1 appropriate. `status`, however, *does* change over the loan
  lifecycle (`applied → approved → disbursed → closed/defaulted`), and duplicating a
  mutable field on an otherwise-static, overwrite-only dimension would make `dim_loan`
  quietly wrong the moment a loan's status changed but the dimension hadn't rebuilt
  from the right source. Current status is tracked in `snap_loan_status` instead, and
  surfaced into `mart_loan_health` and `mart_customer_360` via a direct
  `snap_loan_status` join (`dbt_valid_to is null`) rather than being carried on the
  dimension. Any other downstream consumer that needs loan status (e.g. the `loans`
  semantic model backing `loan_default_rate`) reads it from `mart_loan_health`, not by
  re-joining the snapshot itself, so there's a single place status enters the
  dimensional layer.
- **`dim_cards` — Type 1.** ClearBank issues debit cards only; card attributes are
  treated as current-state-only, no snapshot.
- **`dim_date` — Type 0 / static.** Calendar attributes never change. Also registered
  as the MetricFlow time spine (`standard_granularity_column: date_day`), since the
  semantic layer requires one.

### Conformed dimensions

`dim_customers` and `dim_date` are shared across all three fact tables — this is what
lets a query compare, say, a customer's transaction activity against their loan
repayment activity without going through a mart. `dim_accounts` is conformed across
`fct_transactions` and `fct_loan_disbursement`.

## Source Data

No actual data was provided — six raw tables in the `raw` schema (populated locally via
seeds for development) were assumed to have the following shape:

- **`raw.customers`** — `customer_id` (PK), `first_name`, `middle_name` (nullable),
  `last_name`, `email`, `phone_number`, `date_of_birth`, `address`, `city`, `state`,
  `country`, `nationality`, `gender` (`male`/`female`/`other`), `kyc_status`
  (`pending`/`verified`/`rejected`), `created_at`, `updated_at`.
- **`raw.accounts`** — `account_id` (PK), `account_number`, `customer_id` (FK),
  `account_type` (`current`/`savings`), `currency`, `status`
  (`active`/`dormant`/`closed`), `opened_date`, `closed_date` (nullable), `created_at`,
  `updated_at`.
- **`raw.transactions`** — `transaction_id` (PK), `account_id` (FK), `card_id` (FK,
  nullable), `transaction_date`, `amount`, `currency`, `type` (`debit`/`credit`),
  `status` (`completed`/`pending`/`reversed`), `description` (nullable),
  `reference_number`, `channel` (`atm`/`pos`/`mobile`/`web`/`transfer`),
  `reversal_of_transaction_id` (FK, nullable), `created_at`. `customer_id` is
  intentionally not on this table — it's derived via `account_id → accounts →
  customer_id`. Reversals are separate rows with a negative amount and
  `type = 'credit'`.
- **`raw.loans`** — `loan_id` (PK), `customer_id` (FK), `account_id` (FK),
  `product_type`, `applied_amount`, `approved_amount` (nullable), `disbursed_amount`
  (nullable), `status` (`applied`/`approved`/`disbursed`/`closed`/`defaulted`, linear
  transitions), `application_date`, `approval_date` (nullable), `disbursement_date`
  (nullable), `created_at`, `updated_at`.
- **`raw.loan_repayments`** — `repayment_id` (PK), `loan_id` (FK), `customer_id` (FK),
  `repayment_date`, `amount`, `status` (`successful`/`reversed`/`pending`),
  `created_at`, `updated_at`. Reversed repayments stay in the table and are excluded
  from all balance calculations.
- **`raw.cards`** — `card_id` (PK), `account_id` (FK), `customer_id` (FK), `card_type`
  (`debit` only), `status` (`active`/`blocked`/`expired`/`cancelled`), `issued_date`,
  `expiry_date`, `created_at`, `updated_at`.

**Seed type inference.** The local seed CSVs used for development ship with headers
only (no synthetic rows yet), which meant DuckDB had nothing to sample and defaulted
every column — including dates, timestamps, and IDs — to `INTEGER`. This surfaced as
real compile failures once date-range joins were added (e.g. resolving `dim_customers`
as-of a transaction date). Rather than special-casing casts at every join site, column
types are forced explicitly via `+column_types` in `dbt_project.yml` for all six seeds,
so the schema is correct regardless of whether sample data exists yet.

## Business Logic

- **Reversed transactions**: modeled as separate rows (negative amount,
  `type = 'credit'`, `reversal_of_transaction_id` pointing at the original), not as
  updates to the original row. `fct_transactions.is_reversal` flags them.
  Aggregations use `SUM(amount)`, so reversals net out without special-casing.
- **Reversed repayments**: excluded from every balance calculation via
  `WHERE status != 'reversed'`, applied once in `int_loan_repayments_enriched` so
  every downstream model inherits the exclusion.
- **Outstanding loan balance**: `disbursed_amount − SUM(amount WHERE status =
  'successful')` from repayments, computed as a running total
  (`outstanding_amount_after_repayment`) ordered by `repayment_date`, `created_at`
  within each loan.
- **Running account balance**: `fct_transactions.running_balance` is a cumulative sum
  of `transaction_amount` per account, ordered by `transaction_date`,
  `transaction_id`.
- **`mart_loan_health.loan_health_flag`**: `on_track` if the last activity (repayment,
  or disbursement if no repayment has been made yet) was within 30 days, `at_risk`
  at 31–90 days, `defaulted` beyond 90 days or if `loan_status = 'defaulted'`.
- **`mart_customer_360` / `mart_loan_health` scope**: both marts join only from facts
  and dimensions, never staging directly. `mart_loan_health` inner-joins
  `fct_loan_disbursement`, so it (and the `loans` semantic model built on top of it)
  only ever contains loans that reached disbursement — a loan that was only applied
  for or approved doesn't have a meaningful "health" to report on.

## Incremental Strategy

- **`fct_transactions` — merge on `transaction_id`.** Transactions are append-only
  (reversals are new rows, never updates to an existing one), so a plain merge keyed
  on the natural grain is sufficient. The complication is `running_balance`: a
  cumulative window function can't just be recomputed over the new batch, since new
  rows need to continue from wherever the account's balance last left off. Each
  incremental run reads the last posted balance per account from `{{ this }}` and
  adds the new batch's cumulative sum on top, rather than reprocessing full history.
- **`fct_loan_repayments` — delete+insert, scoped by `loan_id`.** Two things push this
  away from a simple merge: repayment records can be updated after initial load
  (e.g. `pending → successful`), and `outstanding_amount_after_repayment` is a
  running total *per loan* — so a status change on one repayment shifts the balance
  on every later repayment for that same loan, not just the changed row. The model
  first finds every `loan_id` with any repayment touched since the last run, then
  deletes and reinserts that loan's *entire* repayment history from the
  always-fresh `int_loan_repayments_enriched` view, keeping the running balance
  internally consistent. `unique_key = repayment_id` still reflects the table's true
  grain — the widening to "every repayment for an affected loan" happens in the
  query itself, not via the delete key.
- **`fct_loan_disbursement` — merge on `loan_id`.** A loan enters this fact exactly
  once, when `disbursement_date` is first populated; merge on the natural key handles
  both the initial insert and any later correction to that same row.

## Date Dimension

`dim_date` covers **2018-01-01 to 2030-12-31**, generated via
`dbt_utils.date_spine`. The range was chosen to comfortably cover historical banking
activity while leaving forward room for multi-year reporting without needing to
regenerate the seed. Columns include `date_day`, `week_number`, `month_number`,
`month_name`, `quarter`, `year`, `day_of_week`, `day_name`, `is_weekend`,
`is_month_start`, `is_month_end`, `is_quarter_start`, `is_quarter_end`. `dim_date` is
also registered as the project's MetricFlow time spine, so no separate
`metricflow_time_spine` model was created.
