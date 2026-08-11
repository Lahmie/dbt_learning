# ClearBank Analytics

A dbt project building the analytics engineering layer for ClearBank, a fictional
mid-sized digital retail bank. Transactional data (customers, accounts,
transactions, loans, loan repayments, cards) is transformed from raw source
tables into a governed, tested, documented dimensional model — replacing
ad-hoc SQL queries against raw tables with a production-ready star schema.

Built with dbt Core against DuckDB for local development.

## Dimensional model

See [`DIMENSIONAL_MODEL.png`](./DIMENSIONAL_MODEL.png) for the full star
schema diagram and [`ASSUMPTIONS.md`](./ASSUMPTIONS.md) for the design
rationale behind every decision below.

### Fact tables

| Model | Grain | Materialization |
|---|---|---|
| `fct_transactions` | One row per transaction event on one account | Incremental (merge) |
| `fct_loan_repayments` | One row per repayment event against one loan | Incremental (delete+insert, scoped by loan) |
| `fct_loan_disbursement` | One row per disbursement event against one approved loan | Incremental (merge) |

### Dimension tables

| Model | SCD Type | Notes |
|---|---|---|
| `dim_customers` | Type 2 | Conformed — used by all three fact tables. Sourced from `snap_customers`. |
| `dim_accounts` | Type 1 | Current attributes only. Status history in `snap_account_status`. |
| `dim_loan` | Type 1 | Loan terms fixed at origination. Deliberately excludes `status` — see `ASSUMPTIONS.md`. |
| `dim_cards` | Type 1 | ClearBank issues debit cards only; no snapshot needed. |
| `dim_date` | Static | Also registered as the MetricFlow time spine. |

### Reporting marts

- `mart_customer_360` — one row per customer: account count, 90-day transaction
  volume, active loan count, outstanding loan balance, debit card flag,
  current KYC status.
- `mart_loan_health` — one row per disbursed loan: original/disbursed/repaid
  amounts, outstanding balance, days since last repayment, and a derived
  `loan_health_flag` (`on_track` / `at_risk` / `defaulted`).

## Project structure

```
clearbank_analytics/
├── models/
│   ├── staging/          # one model per source table, clean mirror only
│   ├── intermediate/     # business logic joins and enrichment
│   ├── marts/
│   │   ├── dimensions/   # dim_* models
│   │   ├── facts/        # fct_* models
│   │   └── reporting/    # mart_* consumer-facing models
│   ├── _sources.yml
│   ├── _exposures.yml
│   └── _metrics.yml      # semantic models + metrics
├── snapshots/             # snap_* Type 2 history
├── seeds/                 # synthetic raw_* data for local dev
├── tests/                 # custom singular tests
├── macros/
├── DIMENSIONAL_MODEL.png  # star schema diagram
├── ASSUMPTIONS.md         # design decisions and rationale
└── README.md
```

## How to run

### Prerequisites

- dbt Core (developed against 1.11.x) with the `dbt-duckdb` adapter
- A `clearbank_analytics` profile in `~/.dbt/profiles.yml`:

```yaml
clearbank_analytics:
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 1
    prod:
      type: duckdb
      path: prod.duckdb
      threads: 4
  target: dev
```

### Setup

```bash
dbt deps      # install dbt_utils
dbt seed      # load synthetic raw_* data into the raw schema
dbt snapshot  # build Type 2 history (snap_customers, snap_loan_status, snap_account_status)
dbt run       # build staging -> intermediate -> dimensions -> facts -> reporting marts
dbt test      # run generic + singular tests
```

Or, in one shot:

```bash
dbt build
```

`dbt build` runs seeds, snapshots, models and tests together in DAG order —
the snapshots must exist before the dimensional layer builds, since
`dim_customers` reads from `snap_customers` and `mart_loan_health` /
`mart_customer_360` read from `snap_loan_status`.

### Documentation

```bash
dbt docs generate
dbt docs serve
```

Produces the full lineage graph from raw sources through staging,
intermediate, dimensions, facts, and reporting marts.

## Key business logic

- **Reversed transactions**: separate rows with a negative amount and
  `type = 'credit'`, linked back via `reversal_of_transaction_id`. No row is
  ever mutated after load — aggregations net out naturally via `SUM(amount)`.
- **Reversed repayments**: excluded from all balance calculations
  (`status != 'reversed'`).
- **Running balance / outstanding balance**: both `fct_transactions.running_balance`
  and `fct_loan_repayments.outstanding_amount_after_repayment` are cumulative
  running totals — see `ASSUMPTIONS.md` for how each fact table's incremental
  strategy accounts for that.
- **Loan status**: intentionally excluded from `dim_loan` (a Type 1, overwrite-only
  dimension) since `snap_loan_status` already tracks it per stage. Current
  status is surfaced in `mart_loan_health` and `mart_customer_360` via a
  `snap_loan_status` join (`dbt_valid_to is null`), not duplicated on the dimension.
- All surrogate keys are generated with `dbt_utils.generate_surrogate_key()`.

## Exposures & metrics

- **Exposures** (`models/_exposures.yml`): `customer_360_dashboard` and
  `loan_health_report`, each depending on their respective reporting mart.
- **Metrics** (`models/_metrics.yml`): `monthly_active_customers`,
  `average_transaction_value`, and `loan_default_rate` (a ratio of
  `defaulted_loans` / `total_loans`), built on semantic models over
  `fct_transactions` and `mart_loan_health`.
