from __future__ import annotations

import gzip
import json
from collections import defaultdict
from decimal import Decimal
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, MutableMapping, Optional, Set, Tuple

import numpy as np
import pandas as pd

from generator.config import GeneratorSettings
from generator.io import RawTableWriter, write_json


NUMERIC_TYPES = {"integer", "money", "rate"}
DATE_TYPES = {"date", "timestamp"}


def read_table(path: Path) -> pd.DataFrame:
    return pd.read_csv(path, dtype=str, keep_default_na=False)


def null_mask(series: pd.Series) -> pd.Series:
    return series.eq("")


def json_sample(frame: pd.DataFrame, limit: int) -> List[Dict[str, Any]]:
    sample = frame.head(limit).replace("", None)
    return sample.to_dict("records")


def profile_table(
    settings: GeneratorSettings,
    writer: RawTableWriter,
    table: str,
) -> Dict[str, Any]:
    path = writer.path_for(table)
    columns = settings.contract["tables"][table]["columns"]
    chunk_rows = int(settings.config["output"]["profile_chunk_rows"])
    sample_limit = int(settings.config["output"]["sample_rows"])
    row_count = 0
    null_counts = {column: 0 for column in columns}
    samples: List[Dict[str, Any]] = []
    numeric_values: Dict[str, List[np.ndarray]] = defaultdict(list)
    numeric_kept = defaultdict(int)
    temporal_min: Dict[str, Optional[str]] = {
        column: None for column, kind in columns.items() if kind in DATE_TYPES
    }
    temporal_max: Dict[str, Optional[str]] = {
        column: None for column, kind in columns.items() if kind in DATE_TYPES
    }
    max_numeric_sample = 100000

    for chunk in pd.read_csv(
        path,
        dtype=str,
        keep_default_na=False,
        chunksize=chunk_rows,
    ):
        row_count += len(chunk)
        if len(samples) < sample_limit:
            samples.extend(json_sample(chunk, sample_limit - len(samples)))
        for column, kind in columns.items():
            null_counts[column] += int(null_mask(chunk[column]).sum())
            values = chunk.loc[~null_mask(chunk[column]), column]
            if kind in NUMERIC_TYPES and numeric_kept[column] < max_numeric_sample:
                remaining = max_numeric_sample - numeric_kept[column]
                parsed = pd.to_numeric(values.head(remaining), errors="coerce").dropna()
                array = parsed.to_numpy(dtype=float)
                numeric_values[column].append(array)
                numeric_kept[column] += len(array)
            elif kind in DATE_TYPES and not values.empty:
                current_min = str(values.min())
                current_max = str(values.max())
                temporal_min[column] = (
                    current_min
                    if temporal_min[column] is None
                    else min(str(temporal_min[column]), current_min)
                )
                temporal_max[column] = (
                    current_max
                    if temporal_max[column] is None
                    else max(str(temporal_max[column]), current_max)
                )

    column_profiles: Dict[str, Any] = {}
    for column, kind in columns.items():
        details: Dict[str, Any] = {
            "logical_type": kind,
            "null_count": null_counts[column],
            "null_rate": round(null_counts[column] / row_count, 6) if row_count else None,
        }
        if kind in NUMERIC_TYPES and numeric_values[column]:
            values = np.concatenate(numeric_values[column])
            details["quantiles"] = {
                "min": round(float(np.min(values)), 6),
                "p25": round(float(np.quantile(values, 0.25)), 6),
                "p50": round(float(np.quantile(values, 0.50)), 6),
                "p75": round(float(np.quantile(values, 0.75)), 6),
                "p95": round(float(np.quantile(values, 0.95)), 6),
                "max": round(float(np.max(values)), 6),
                "sampled_values": len(values),
            }
        if kind in DATE_TYPES:
            details["min"] = temporal_min[column]
            details["max"] = temporal_max[column]
        column_profiles[column] = details
    return {
        "path": str(path.relative_to(settings.project_root)),
        "row_count": row_count,
        "compressed_bytes": path.stat().st_size,
        "columns": column_profiles,
        "sample_rows": samples,
        "numeric_quantiles_are_approximate": True,
    }


def make_check(
    name: str,
    passed: bool,
    details: str,
    metrics: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    return {
        "name": name,
        "status": "PASS" if passed else "FAIL",
        "details": details,
        "metrics": metrics or {},
    }


def key_set(frame: pd.DataFrame, column: str) -> Set[str]:
    return set(frame.loc[frame[column] != "", column])


def decimal_series(frame: pd.DataFrame, column: str) -> pd.Series:
    return frame[column].map(lambda value: Decimal(value or "0"))


def validate_schema_headers(
    settings: GeneratorSettings, writer: RawTableWriter
) -> List[Dict[str, Any]]:
    checks = []
    for table, table_contract in settings.contract["tables"].items():
        with gzip.open(writer.path_for(table), "rt", encoding="utf-8") as handle:
            actual = handle.readline().rstrip("\n").split(",")
        expected = list(table_contract["columns"])
        checks.append(
            make_check(
                f"schema:{table}",
                actual == expected,
                "CSV header matches schema_contract.yaml exactly",
                {"expected_columns": len(expected), "actual_columns": len(actual)},
            )
        )
    return checks


def validate_small_tables(
    settings: GeneratorSettings,
    writer: RawTableWriter,
) -> Tuple[List[Dict[str, Any]], Dict[str, pd.DataFrame]]:
    tables = {
        table: read_table(writer.path_for(table))
        for table in settings.contract["tables"]
        if table != "fact_events"
    }
    checks: List[Dict[str, Any]] = []
    for table, contract in settings.contract["tables"].items():
        if table == "fact_events":
            continue
        frame = tables[table]
        keys = contract.get("primary_key", [])
        duplicate_count = int(frame.duplicated(keys).sum())
        null_key_count = int((frame[keys] == "").any(axis=1).sum())
        checks.append(
            make_check(
                f"primary_key:{table}",
                duplicate_count == 0 and null_key_count == 0,
                "Primary key is unique and non-null",
                {
                    "duplicate_rows": duplicate_count,
                    "null_key_rows": null_key_count,
                },
            )
        )

    users = key_set(tables["dim_users"], "user_id")
    products = key_set(tables["dim_products"], "product_id")
    campaigns = key_set(tables["dim_campaign"], "campaign_id")
    contents = key_set(tables["dim_content"], "content_id")
    orders = key_set(tables["fact_orders"], "order_id")
    sessions = key_set(tables["fact_sessions"], "session_id")
    fk_specs = [
        ("fact_orders.user_id", tables["fact_orders"], "user_id", users),
        ("fact_orders.session_id", tables["fact_orders"], "session_id", sessions),
        ("fact_order_items.order_id", tables["fact_order_items"], "order_id", orders),
        ("fact_order_items.product_id", tables["fact_order_items"], "product_id", products),
        ("rank_history.user_id", tables["dim_membership_rank_history"], "user_id", users),
        ("identity.user_id", tables["bridge_user_identity"], "user_id", users),
        ("campaign_cost.campaign_id", tables["fact_campaign_cost_daily"], "campaign_id", campaigns),
        ("touchpoint.order_id", tables["int_order_touchpoints"], "order_id", orders),
        ("touchpoint.session_id", tables["int_order_touchpoints"], "session_id", sessions),
    ]
    for name, frame, column, parent in fk_specs:
        values = key_set(frame, column)
        orphan = values - parent
        checks.append(
            make_check(
                f"foreign_key:{name}",
                not orphan,
                "All non-null values reference the parent table",
                {"orphan_values": len(orphan)},
            )
        )

    items = tables["fact_order_items"].copy()
    item_equations = {
        "item_gross_sales": decimal_series(items, "quantity")
        * decimal_series(items, "unit_list_price"),
        "item_discount_amount": decimal_series(items, "item_gross_sales")
        - decimal_series(items, "item_net_sales"),
        "item_cost": decimal_series(items, "quantity")
        * decimal_series(items, "unit_cost"),
        "item_gross_profit": decimal_series(items, "item_net_sales")
        - decimal_series(items, "item_cost"),
    }
    for column, expected in item_equations.items():
        actual = decimal_series(items, column)
        mismatches = int(
            sum(abs(left - right) > Decimal("0.01") for left, right in zip(actual, expected))
        )
        checks.append(
            make_check(
                f"money_equation:fact_order_items.{column}",
                mismatches == 0,
                "Line-level monetary equation holds within 0.01",
                {"mismatched_rows": mismatches},
            )
        )

    orders_frame = tables["fact_orders"].copy()
    item_grouped = items.assign(
        item_gross_sales_d=decimal_series(items, "item_gross_sales"),
        item_discount_amount_d=decimal_series(items, "item_discount_amount"),
        item_net_sales_d=decimal_series(items, "item_net_sales"),
    ).groupby("order_id").agg(
        gross_sales=("item_gross_sales_d", "sum"),
        discount_amount=("item_discount_amount_d", "sum"),
        item_net_sales=("item_net_sales_d", "sum"),
    )
    header_mismatches = 0
    total_mismatches = 0
    recognized_mismatches = 0
    for row in orders_frame.itertuples():
        grouped = item_grouped.loc[row.order_id]
        if any(
            abs(Decimal(getattr(row, column)) - Decimal(str(grouped[column])))
            > Decimal("0.01")
            for column in ("gross_sales", "discount_amount", "item_net_sales")
        ):
            header_mismatches += 1
        expected_total = (
            Decimal(row.item_net_sales)
            + Decimal(row.tax_amount)
            + Decimal(row.shipping_amount)
        )
        if abs(Decimal(row.order_total) - expected_total) > Decimal("0.01"):
            total_mismatches += 1
        expected_recognized = (
            Decimal(row.item_net_sales)
            if row.order_status == "completed"
            else Decimal("0")
        )
        if abs(Decimal(row.recognized_revenue) - expected_recognized) > Decimal("0.01"):
            recognized_mismatches += 1
    checks.extend(
        [
            make_check(
                "money_equation:order_header_vs_items",
                header_mismatches == 0,
                "Header gross, discount and item net equal item sums",
                {"mismatched_orders": header_mismatches},
            ),
            make_check(
                "money_equation:order_total",
                total_mismatches == 0,
                "order_total = item_net_sales + tax + shipping",
                {"mismatched_orders": total_mismatches},
            ),
            make_check(
                "money_equation:recognized_revenue",
                recognized_mismatches == 0,
                "Completed recognizes item net; cancelled/refunded recognizes zero",
                {"mismatched_orders": recognized_mismatches},
            ),
        ]
    )

    cost = tables["fact_campaign_cost_daily"]
    invalid_cost = int(
        (
            (pd.to_numeric(cost["cost"]) < 0)
            | (pd.to_numeric(cost["impressions"]) < pd.to_numeric(cost["clicks"]))
        ).sum()
    )
    checks.append(
        make_check(
            "campaign_cost:bounds",
            invalid_cost == 0,
            "Cost is non-negative and impressions >= clicks",
            {"invalid_rows": invalid_cost},
        )
    )

    touchpoints = tables["int_order_touchpoints"]
    if touchpoints.empty:
        checks.append(
            make_check(
                "attribution:credits",
                False,
                "No touchpoints were generated",
            )
        )
    else:
        grouped = touchpoints.groupby("order_id").agg(
            last=("last_touch_credit", lambda s: sum(Decimal(v) for v in s)),
            linear=("linear_credit", lambda s: sum(Decimal(v) for v in s)),
            lookback=("days_before_purchase", lambda s: max(int(v) for v in s)),
        )
        bad_credit = int(
            sum(
                abs(row.last - Decimal("1")) > Decimal("0.000001")
                or abs(row.linear - Decimal("1")) > Decimal("0.000001")
                for row in grouped.itertuples()
            )
        )
        bad_lookback = int((grouped["lookback"] > settings.config["attribution"]["lookback_days"]).sum())
        checks.append(
            make_check(
                "attribution:credits",
                bad_credit == 0 and bad_lookback == 0,
                "Each attributed order sums to 1.0 for both models and stays in lookback",
                {
                    "orders": len(grouped),
                    "bad_credit_orders": bad_credit,
                    "bad_lookback_orders": bad_lookback,
                },
            )
        )
    return checks, tables


def validate_events(
    settings: GeneratorSettings,
    writer: RawTableWriter,
    tables: Mapping[str, pd.DataFrame],
) -> Tuple[List[Dict[str, Any]], Dict[str, int]]:
    checks: List[Dict[str, Any]] = []
    event_ids: Set[str] = set()
    duplicate_ids = 0
    event_counts: Dict[str, int] = defaultdict(int)
    counts_by_session: Dict[str, int] = defaultdict(int)
    reached: Dict[str, Set[str]] = {
        name: set()
        for name in ("view_item", "add_to_cart", "begin_checkout", "purchase")
    }
    order_ids = key_set(tables["fact_orders"], "order_id")
    product_ids = key_set(tables["dim_products"], "product_id")
    content_ids = key_set(tables["dim_content"], "content_id")
    session_ids = key_set(tables["fact_sessions"], "session_id")
    event_order_ids: Set[str] = set()
    purchase_order_counts: Dict[str, int] = defaultdict(int)
    last_sequence: Dict[str, int] = {}
    last_timestamp: Dict[str, str] = {}
    sequence_errors = 0
    orphan_sessions = orphan_orders = orphan_products = orphan_contents = 0
    chunk_rows = int(settings.config["output"]["profile_chunk_rows"])
    for chunk in pd.read_csv(
        writer.path_for("fact_events"),
        dtype=str,
        keep_default_na=False,
        chunksize=chunk_rows,
    ):
        for event_id in chunk["event_id"]:
            if event_id in event_ids:
                duplicate_ids += 1
            event_ids.add(event_id)
        orphan_sessions += int((~chunk["session_id"].isin(session_ids)).sum())
        orphan_orders += int(
            ((chunk["order_id"] != "") & (~chunk["order_id"].isin(order_ids))).sum()
        )
        orphan_products += int(
            ((chunk["product_id"] != "") & (~chunk["product_id"].isin(product_ids))).sum()
        )
        orphan_contents += int(
            ((chunk["content_id"] != "") & (~chunk["content_id"].isin(content_ids))).sum()
        )
        event_order_ids.update(chunk.loc[chunk["event_name"] == "purchase", "order_id"])
        for order_id in chunk.loc[chunk["event_name"] == "purchase", "order_id"]:
            purchase_order_counts[str(order_id)] += 1
        for row in chunk[
            ["session_id", "event_sequence", "event_timestamp"]
        ].itertuples(index=False):
            sequence = int(row.event_sequence)
            expected = last_sequence.get(row.session_id, 0) + 1
            if sequence != expected:
                sequence_errors += 1
            previous_timestamp = last_timestamp.get(row.session_id)
            if previous_timestamp is not None and row.event_timestamp < previous_timestamp:
                sequence_errors += 1
            last_sequence[row.session_id] = sequence
            last_timestamp[row.session_id] = row.event_timestamp
        for name, count in chunk["event_name"].value_counts().items():
            event_counts[str(name)] += int(count)
        for session_id, count in chunk["session_id"].value_counts().items():
            counts_by_session[str(session_id)] += int(count)
        for name in reached:
            reached[name].update(chunk.loc[chunk["event_name"] == name, "session_id"])

    checks.append(
        make_check(
            "primary_key:fact_events",
            duplicate_ids == 0 and len(event_ids) == settings.scale["events"],
            "event_id is unique and event count matches selected scale",
            {
                "rows": len(event_ids) + duplicate_ids,
                "unique_ids": len(event_ids),
                "duplicate_ids": duplicate_ids,
                "expected_rows": settings.scale["events"],
            },
        )
    )
    checks.append(
        make_check(
            "foreign_key:fact_events",
            sum((orphan_sessions, orphan_orders, orphan_products, orphan_contents)) == 0,
            "Event references resolve when non-null",
            {
                "orphan_sessions": orphan_sessions,
                "orphan_orders": orphan_orders,
                "orphan_products": orphan_products,
                "orphan_contents": orphan_contents,
            },
        )
    )
    expected_session_counts = tables["fact_sessions"].set_index("session_id")["event_count"]
    session_count_mismatches = sum(
        int(expected_session_counts.get(session_id, "-1")) != actual
        for session_id, actual in counts_by_session.items()
    )
    missing_sessions = session_ids - set(counts_by_session)
    checks.append(
        make_check(
            "events:session_event_count",
            session_count_mismatches == 0
            and not missing_sessions
            and sequence_errors == 0,
            "Event counts aggregate to sessions and sequence/timestamp is monotonic",
            {
                "mismatched_sessions": session_count_mismatches,
                "missing_sessions": len(missing_sessions),
                "sequence_or_timestamp_errors": sequence_errors,
            },
        )
    )
    funnel_nested = (
        reached["purchase"] <= reached["begin_checkout"]
        and reached["begin_checkout"] <= reached["add_to_cart"]
        and reached["add_to_cart"] <= reached["view_item"]
    )
    checks.append(
        make_check(
            "funnel:nested_sessions",
            funnel_nested,
            "Purchase ⊆ checkout ⊆ cart ⊆ item-view at session grain",
            {name: len(values) for name, values in reached.items()},
        )
    )
    missing_purchase_events = order_ids - event_order_ids
    duplicate_purchase_events = sum(
        count != 1 for count in purchase_order_counts.values()
    )
    checks.append(
        make_check(
            "purchase_event:order_match",
            not missing_purchase_events
            and event_order_ids <= order_ids
            and duplicate_purchase_events == 0,
            "Every generated order has exactly one matching purchase event",
            {
                "orders": len(order_ids),
                "purchase_event_orders": len(event_order_ids),
                "missing_orders": len(missing_purchase_events),
                "non_singleton_purchase_event_orders": duplicate_purchase_events,
            },
        )
    )
    return checks, dict(event_counts)


def build_reports(
    settings: GeneratorSettings,
    writer: RawTableWriter,
    generation_summary: Dict[str, Any],
) -> Tuple[Path, Path, bool]:
    settings.reports_root.mkdir(parents=True, exist_ok=True)
    profiles = {
        table: profile_table(settings, writer, table)
        for table in settings.contract["tables"]
    }
    checks = validate_schema_headers(settings, writer)
    configured_rows = {
        "dim_users": settings.scale["users"],
        "dim_products": settings.scale["products"],
        "dim_campaign": settings.scale["campaigns"],
        "dim_content": settings.scale["contents"],
        "fact_sessions": settings.scale["sessions"],
        "fact_events": settings.scale["events"],
        "fact_orders": settings.scale["orders"],
        "fact_order_items": settings.scale["order_items"],
    }
    for table, expected in configured_rows.items():
        actual = profiles[table]["row_count"]
        checks.append(
            make_check(
                f"configured_row_count:{table}",
                actual == expected,
                "Generated row count matches the selected scale",
                {"expected": expected, "actual": actual},
            )
        )
    small_checks, tables = validate_small_tables(settings, writer)
    event_checks, event_counts = validate_events(settings, writer, tables)
    checks.extend(small_checks)
    checks.extend(event_checks)
    passed = all(check["status"] == "PASS" for check in checks)
    profile = {
        "generator": {
            "version": 1,
            "scale": settings.scale_name,
            "seed": settings.config["seed"],
            "period": settings.config["period"],
        },
        "generation_summary": generation_summary,
        "event_counts": event_counts,
        "tables": profiles,
        "quality_summary": {
            "status": "PASS" if passed else "FAIL",
            "passed": sum(check["status"] == "PASS" for check in checks),
            "failed": sum(check["status"] == "FAIL" for check in checks),
        },
    }
    profile_path = settings.reports_root / "profile.json"
    write_json(profile_path, profile)

    lines = [
        "# Generated Data Quality Report",
        "",
        f"- Scale: `{settings.scale_name}`",
        f"- Seed: `{settings.config['seed']}`",
        f"- Period: `{settings.config['period']['start_date']}` to `{settings.config['period']['end_date']}`",
        f"- Overall status: **{'PASS' if passed else 'FAIL'}**",
        f"- Checks: {sum(c['status'] == 'PASS' for c in checks)} passed / {sum(c['status'] == 'FAIL' for c in checks)} failed",
        "",
        "## Table row counts",
        "",
        "| Table | Rows | Compressed bytes |",
        "|---|---:|---:|",
    ]
    for table, details in profiles.items():
        lines.append(
            f"| `{table}` | {details['row_count']:,} | {details['compressed_bytes']:,} |"
        )
    lines.extend(
        [
            "",
            "## Funnel reach",
            "",
            "| Event | Event rows |",
            "|---|---:|",
        ]
    )
    for event_name in ("view_item", "add_to_cart", "begin_checkout", "purchase"):
        lines.append(f"| `{event_name}` | {event_counts.get(event_name, 0):,} |")
    lines.extend(
        [
            "",
            "## Quality checks",
            "",
            "| Status | Check | Details | Metrics |",
            "|---|---|---|---|",
        ]
    )
    for check in checks:
        metrics = json.dumps(check["metrics"], ensure_ascii=False, sort_keys=True)
        lines.append(
            f"| {check['status']} | `{check['name']}` | {check['details']} | `{metrics}` |"
        )
    lines.extend(
        [
            "",
            "## Samples and distributions",
            "",
            "Each table's first 20 deterministic sample rows, NULL rates, temporal ranges, "
            "and approximate numeric quantiles are stored in `profile.json`. Numeric quantiles "
            "use at most the first 100,000 non-null values per column to bound memory.",
            "",
        ]
    )
    quality_path = settings.reports_root / "quality_report.md"
    quality_path.write_text("\n".join(lines), encoding="utf-8")
    return profile_path, quality_path, passed
