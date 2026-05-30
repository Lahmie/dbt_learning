# Real Estate dbt Project

A learning project that models real estate transactional data using dbt and Snowflake. Raw OLTP data is transformed through four model layers into a star schema ready for analytics.

---

## Stack

- **Warehouse:** Snowflake
- **Transformation:** dbt Core 1.11
- **Packages:** dbt-utils

---

## Source Data

Database: `RAW_REAL_ESTATE` | Schema: `transactional_data`

| Table | Description |
|---|---|
| `db_agents` | Agent records with office and level info |
| `db_clients` | Client contact information |
| `db_offices` | Office name and address |
| `db_properties` | Property records with location and type foreign keys |
| `db_status` | Transaction status lookup |
| `db_transactions` | Core transaction events — price, dates, foreign keys |
| `location_hierarchy` | Suburb, postcode, state, region hierarchy |
| `property_types` | Property type and category lookup |

---

## Project Structure

```
models/
├── base/          # One model per source table. Renamed columns, recast types. Views.
├── prep/          # Joins and business logic. Foreign keys resolved. Tables.
├── dimensional/   # Star schema — dim_ and fct_ tables with surrogate keys. Tables.
└── present/       # Wide, aggregated, analyst-facing tables. Tables.
```

---

## Model Layers

### Layer 1 — Base (`models/base/`)

One model per source table. No business logic. Columns renamed to snake_case, types cast explicitly.

| Model | Source |
|---|---|
| `base_db_agents` | `db_agents` |
| `base_db_clients` | `db_clients` |
| `base_db_offices` | `db_offices` |
| `base_db_properties` | `db_properties` |
| `base_db_status` | `db_status` |
| `base_db_transactions` | `db_transactions` |
| `base_property_types` | `property_types` |
| `base_location_hierarchy` | `location_hierarchy` |

### Layer 2 — Prep (`models/prep/`)

Foreign keys resolved, related tables joined, derived columns added.

| Model | Description |
|---|---|
| `prep_properties` | Properties enriched with type name, category, suburb, state, region |
| `prep_agents` | Agents enriched with office name and address |
| `prep_clients` | Clients pass-through — no foreign keys to resolve |
| `prep_transactions` | Transactions joined to properties, agents, clients, and status. Adds `duration_days` and `is_completed` |

### Layer 3 — Dimensional (`models/dimensional/`)

Star schema. Surrogate keys generated via `dbt_utils.generate_surrogate_key`.

| Model | Type | Description |
|---|---|---|
| `dim_property` | Dimension | Property type, category, and full location hierarchy |
| `dim_agent` | Dimension | Agent details with office information |
| `dim_client` | Dimension | Client contact information |
| `dim_date` | Dimension | Date spine from 2020–2030 with year, month, quarter, day of week, is_weekend |
| `fct_transactions` | Fact | One row per transaction — price, duration, foreign keys to all dims |

### Layer 4 — Present (`models/present/`)

Aggregated, business-friendly tables for BI and analysis.

| Model | Description |
|---|---|
| `present_sales_overview` | Total transactions, revenue, and avg deal size by month and region |
| `present_agent_performance` | Deals closed, total revenue, and avg deal duration per agent |
| `present_property_insights` | Avg price by property type, region, and month |
| `present_client_360` | Full transaction history per client with property and agent details |

---

## Lineage

```
source tables
    └── base_*
            └── prep_*
                    └── dim_* / fct_*
                                └── present_*
```

---

## Getting Started

### Prerequisites

- dbt Core installed
- Snowflake credentials configured in `~/.dbt/profiles.yml`

### Setup

```bash
# Install dependencies
dbt deps

# Run all models
dbt build

# Run a specific layer
dbt build --select models/base/*
dbt build --select models/prep/*
dbt build --select models/dimensional/*
dbt build --select models/present/*
```

### Generate Documentation

```bash
dbt docs generate
dbt docs serve
```

---

## Key Design Decisions

- **Surrogate keys** — all dimensional models use hashed surrogate keys via `dbt_utils.generate_surrogate_key` rather than natural keys from the source system
- **`is_completed` flag** — derived from `transaction_completed_time IS NOT NULL` rather than the `status` column, which contains data quality issues
- **`inner join` in prep and dimensional layers** — surfaces referential integrity issues rather than silently producing NULLs
- **`prep_clients` is a pass-through** — the clients table has no foreign keys to resolve at the prep layer