# Generated Data Quality Report

- Scale: `full`
- Seed: `20240724`
- Period: `2024-01-01` to `2025-12-31`
- Overall status: **PASS**
- Checks: 56 passed / 0 failed

## Table row counts

| Table | Rows | Compressed bytes |
|---|---:|---:|
| `dim_date` | 731 | 7,045 |
| `dim_users` | 40,000 | 797,802 |
| `dim_membership_rank_history` | 43,797 | 234,831 |
| `bridge_user_identity` | 44,980 | 569,245 |
| `dim_products` | 800 | 17,937 |
| `dim_campaign` | 24 | 454 |
| `dim_content` | 180 | 4,063 |
| `fact_orders` | 10,800 | 438,164 |
| `fact_order_items` | 17,800 | 328,349 |
| `fact_events` | 1,350,000 | 23,916,476 |
| `fact_sessions` | 220,000 | 7,395,721 |
| `fact_campaign_cost_daily` | 6,048 | 73,748 |
| `int_order_touchpoints` | 15,337 | 323,513 |

## Funnel reach

| Event | Event rows |
|---|---:|
| `view_item` | 100,100 |
| `add_to_cart` | 27,940 |
| `begin_checkout` | 16,940 |
| `purchase` | 10,800 |

## Quality checks

| Status | Check | Details | Metrics |
|---|---|---|---|
| PASS | `schema:dim_date` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 16, "expected_columns": 16}` |
| PASS | `schema:dim_users` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 17, "expected_columns": 17}` |
| PASS | `schema:dim_membership_rank_history` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 6, "expected_columns": 6}` |
| PASS | `schema:bridge_user_identity` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 7, "expected_columns": 7}` |
| PASS | `schema:dim_products` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 12, "expected_columns": 12}` |
| PASS | `schema:dim_campaign` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 11, "expected_columns": 11}` |
| PASS | `schema:dim_content` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 11, "expected_columns": 11}` |
| PASS | `schema:fact_orders` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 21, "expected_columns": 21}` |
| PASS | `schema:fact_order_items` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 14, "expected_columns": 14}` |
| PASS | `schema:fact_events` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 27, "expected_columns": 27}` |
| PASS | `schema:fact_sessions` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 23, "expected_columns": 23}` |
| PASS | `schema:fact_campaign_cost_daily` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 10, "expected_columns": 10}` |
| PASS | `schema:int_order_touchpoints` | CSV header matches schema_contract.yaml exactly | `{"actual_columns": 17, "expected_columns": 17}` |
| PASS | `configured_row_count:dim_users` | Generated row count matches the selected scale | `{"actual": 40000, "expected": 40000}` |
| PASS | `configured_row_count:dim_products` | Generated row count matches the selected scale | `{"actual": 800, "expected": 800}` |
| PASS | `configured_row_count:dim_campaign` | Generated row count matches the selected scale | `{"actual": 24, "expected": 24}` |
| PASS | `configured_row_count:dim_content` | Generated row count matches the selected scale | `{"actual": 180, "expected": 180}` |
| PASS | `configured_row_count:fact_sessions` | Generated row count matches the selected scale | `{"actual": 220000, "expected": 220000}` |
| PASS | `configured_row_count:fact_events` | Generated row count matches the selected scale | `{"actual": 1350000, "expected": 1350000}` |
| PASS | `configured_row_count:fact_orders` | Generated row count matches the selected scale | `{"actual": 10800, "expected": 10800}` |
| PASS | `configured_row_count:fact_order_items` | Generated row count matches the selected scale | `{"actual": 17800, "expected": 17800}` |
| PASS | `primary_key:dim_date` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:dim_users` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:dim_membership_rank_history` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:bridge_user_identity` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:dim_products` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:dim_campaign` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:dim_content` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:fact_orders` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:fact_order_items` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:fact_sessions` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:fact_campaign_cost_daily` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `primary_key:int_order_touchpoints` | Primary key is unique and non-null | `{"duplicate_rows": 0, "null_key_rows": 0}` |
| PASS | `foreign_key:fact_orders.user_id` | All non-null values reference the parent table | `{"orphan_values": 0}` |
| PASS | `foreign_key:fact_orders.session_id` | All non-null values reference the parent table | `{"orphan_values": 0}` |
| PASS | `foreign_key:fact_order_items.order_id` | All non-null values reference the parent table | `{"orphan_values": 0}` |
| PASS | `foreign_key:fact_order_items.product_id` | All non-null values reference the parent table | `{"orphan_values": 0}` |
| PASS | `foreign_key:rank_history.user_id` | All non-null values reference the parent table | `{"orphan_values": 0}` |
| PASS | `foreign_key:identity.user_id` | All non-null values reference the parent table | `{"orphan_values": 0}` |
| PASS | `foreign_key:campaign_cost.campaign_id` | All non-null values reference the parent table | `{"orphan_values": 0}` |
| PASS | `foreign_key:touchpoint.order_id` | All non-null values reference the parent table | `{"orphan_values": 0}` |
| PASS | `foreign_key:touchpoint.session_id` | All non-null values reference the parent table | `{"orphan_values": 0}` |
| PASS | `money_equation:fact_order_items.item_gross_sales` | Line-level monetary equation holds within 0.01 | `{"mismatched_rows": 0}` |
| PASS | `money_equation:fact_order_items.item_discount_amount` | Line-level monetary equation holds within 0.01 | `{"mismatched_rows": 0}` |
| PASS | `money_equation:fact_order_items.item_cost` | Line-level monetary equation holds within 0.01 | `{"mismatched_rows": 0}` |
| PASS | `money_equation:fact_order_items.item_gross_profit` | Line-level monetary equation holds within 0.01 | `{"mismatched_rows": 0}` |
| PASS | `money_equation:order_header_vs_items` | Header gross, discount and item net equal item sums | `{"mismatched_orders": 0}` |
| PASS | `money_equation:order_total` | order_total = item_net_sales + tax + shipping | `{"mismatched_orders": 0}` |
| PASS | `money_equation:recognized_revenue` | Completed recognizes item net; cancelled/refunded recognizes zero | `{"mismatched_orders": 0}` |
| PASS | `campaign_cost:bounds` | Cost is non-negative and impressions >= clicks | `{"invalid_rows": 0}` |
| PASS | `attribution:credits` | Each attributed order sums to 1.0 for both models and stays in lookback | `{"bad_credit_orders": 0, "bad_lookback_orders": 0, "orders": 10800}` |
| PASS | `primary_key:fact_events` | event_id is unique and event count matches selected scale | `{"duplicate_ids": 0, "expected_rows": 1350000, "rows": 1350000, "unique_ids": 1350000}` |
| PASS | `foreign_key:fact_events` | Event references resolve when non-null | `{"orphan_contents": 0, "orphan_orders": 0, "orphan_products": 0, "orphan_sessions": 0}` |
| PASS | `events:session_event_count` | Event counts aggregate to sessions and sequence/timestamp is monotonic | `{"mismatched_sessions": 0, "missing_sessions": 0, "sequence_or_timestamp_errors": 0}` |
| PASS | `funnel:nested_sessions` | Purchase ⊆ checkout ⊆ cart ⊆ item-view at session grain | `{"add_to_cart": 27940, "begin_checkout": 16940, "purchase": 10500, "view_item": 100100}` |
| PASS | `purchase_event:order_match` | Every generated order has exactly one matching purchase event | `{"missing_orders": 0, "non_singleton_purchase_event_orders": 0, "orders": 10800, "purchase_event_orders": 10800}` |

## Samples and distributions

Each table's first 20 deterministic sample rows, NULL rates, temporal ranges, and approximate numeric quantiles are stored in `profile.json`. Numeric quantiles use at most the first 100,000 non-null values per column to bound memory.
