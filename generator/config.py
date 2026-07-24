from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Optional

import yaml


@dataclass(frozen=True)
class GeneratorSettings:
    config: Dict[str, Any]
    contract: Dict[str, Any]
    project_root: Path
    output_root: Path
    reports_root: Path
    scale_name: str
    scale: Dict[str, int]


def _assert_probability_map(name: str, values: Dict[str, float]) -> None:
    total = sum(float(value) for value in values.values())
    if abs(total - 1.0) > 1e-9:
        raise ValueError(f"{name} probabilities must sum to 1.0; got {total}")
    if any(float(value) < 0 for value in values.values()):
        raise ValueError(f"{name} probabilities must be non-negative")


def load_settings(
    config_path: Path,
    contract_path: Path,
    scale_override: Optional[str] = None,
    output_override: Optional[Path] = None,
) -> GeneratorSettings:
    config = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    contract = yaml.safe_load(contract_path.read_text(encoding="utf-8"))
    scale_name = scale_override or str(config["scale"])
    if scale_name not in config["scales"]:
        raise ValueError(f"Unknown scale {scale_name!r}; choose from {sorted(config['scales'])}")

    _assert_probability_map(
        "users.regions", config["users"]["regions"]
    )
    _assert_probability_map(
        "users.age_bands", config["users"]["age_bands"]
    )
    _assert_probability_map(
        "users.genders", config["users"]["genders"]
    )
    _assert_probability_map(
        "users.registration_channels", config["users"]["registration_channels"]
    )
    _assert_probability_map(
        "channels",
        {
            name: values["probability"]
            for name, values in config["channels"].items()
        },
    )
    _assert_probability_map("devices", config["devices"])
    _assert_probability_map("contents.types", config["contents"]["types"])
    _assert_probability_map(
        "orders.line_count_probabilities",
        config["orders"]["line_count_probabilities"],
    )
    if abs(sum(config["orders"]["discount_rate_probabilities"]) - 1.0) > 1e-9:
        raise ValueError("orders.discount_rate_probabilities must sum to 1.0")

    start = config["period"]["start_date"]
    end = config["period"]["end_date"]
    if start > end:
        raise ValueError("period.start_date must be on or before period.end_date")

    scale = {key: int(value) for key, value in config["scales"][scale_name].items()}
    funnel = config["funnel"]
    nested_counts = [
        round(scale["sessions"] * float(funnel["view_item_sessions_ratio"])),
        round(scale["sessions"] * float(funnel["add_to_cart_sessions_ratio"])),
        round(scale["sessions"] * float(funnel["begin_checkout_sessions_ratio"])),
        scale["purchase_sessions"],
    ]
    if nested_counts != sorted(nested_counts, reverse=True):
        raise ValueError(f"Funnel counts must be monotonically decreasing: {nested_counts}")
    if scale["orders"] < scale["purchase_sessions"]:
        raise ValueError("orders must be >= purchase_sessions")
    if scale["order_items"] < scale["orders"]:
        raise ValueError("order_items must be >= orders")
    minimum_events = (
        2 * scale["sessions"]
        + nested_counts[0]
        + nested_counts[1]
        + nested_counts[2]
        + scale["orders"]
    )
    if scale["events"] < minimum_events:
        raise ValueError(
            f"events={scale['events']} is below minimum funnel event count {minimum_events}"
        )

    project_root = config_path.resolve().parent.parent
    output_root = output_override or project_root / config["output"]["root"]
    reports_root = project_root / config["output"]["reports"]
    return GeneratorSettings(
        config=config,
        contract=contract,
        project_root=project_root,
        output_root=output_root,
        reports_root=reports_root,
        scale_name=scale_name,
        scale=scale,
    )
