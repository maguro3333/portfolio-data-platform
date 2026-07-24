from __future__ import annotations

import math
from collections import defaultdict
from datetime import date, datetime, time, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
from typing import Any, Dict, Iterable, List, Mapping, Optional, Sequence, Tuple

import numpy as np
import pandas as pd

from generator.config import GeneratorSettings
from generator.io import RawTableWriter


MONEY = Decimal("0.01")
CREDIT = Decimal("0.000001")
UTC = timezone.utc
JST = timezone(timedelta(hours=9))


def money(value: Any) -> Decimal:
    return Decimal(str(value)).quantize(MONEY, rounding=ROUND_HALF_UP)


def credit(value: Any) -> Decimal:
    return Decimal(str(value)).quantize(CREDIT, rounding=ROUND_HALF_UP)


def stable_id(prefix: str, number: int, width: int = 8) -> str:
    return f"{prefix}_{number:0{width}d}"


def weighted_choice(
    rng: np.random.Generator, probabilities: Mapping[str, float], size: int
) -> np.ndarray:
    names = np.array(list(probabilities), dtype=object)
    weights = np.array(list(probabilities.values()), dtype=float)
    return rng.choice(names, size=size, p=weights / weights.sum())


def fixed_timestamp(settings: GeneratorSettings) -> datetime:
    end = date.fromisoformat(settings.config["period"]["end_date"])
    return datetime.combine(end + timedelta(days=1), time(0), tzinfo=UTC)


def period_dates(settings: GeneratorSettings) -> pd.DatetimeIndex:
    return pd.date_range(
        settings.config["period"]["start_date"],
        settings.config["period"]["end_date"],
        freq="D",
    )


def sale_period_for(
    day: date, config: Dict[str, Any]
) -> Tuple[bool, Optional[str], float, float]:
    for period in config["seasonality"]["periods"]:
        if date.fromisoformat(period["start"]) <= day <= date.fromisoformat(period["end"]):
            return True, period["name"], float(period["traffic"]), float(period["conversion"])
    return False, None, 1.0, 1.0


def season_name(month: int) -> str:
    if month in (3, 4, 5):
        return "spring"
    if month in (6, 7, 8):
        return "summer"
    if month in (9, 10, 11):
        return "autumn"
    return "winter"


def generate_dim_date(settings: GeneratorSettings) -> pd.DataFrame:
    holidays = {
        "01-01": "New Year's Day",
        "02-11": "National Foundation Day",
        "04-29": "Showa Day",
        "05-03": "Constitution Memorial Day",
        "05-04": "Greenery Day",
        "05-05": "Children's Day",
        "11-03": "Culture Day",
        "11-23": "Labor Thanksgiving Day",
    }
    rows: List[Dict[str, Any]] = []
    for timestamp in period_dates(settings):
        day = timestamp.date()
        is_sale, sale_name, _, _ = sale_period_for(day, settings.config)
        holiday_name = holidays.get(day.strftime("%m-%d"))
        iso = day.isocalendar()
        rows.append(
            {
                "date_key": int(day.strftime("%Y%m%d")),
                "calendar_date": day,
                "calendar_year": day.year,
                "calendar_quarter": (day.month - 1) // 3 + 1,
                "calendar_month": day.month,
                "year_month": day.strftime("%Y-%m"),
                "iso_week": iso.week,
                "day_of_month": day.day,
                "day_of_week": day.isoweekday(),
                "day_name": day.strftime("%A"),
                "is_weekend": day.weekday() >= 5,
                "is_holiday": holiday_name is not None,
                "holiday_name": holiday_name,
                "season": season_name(day.month),
                "is_sale_period": is_sale,
                "sale_period_name": sale_name,
            }
        )
    return pd.DataFrame(rows)


def registration_source(channel: str, channels: Dict[str, Any]) -> Tuple[str, str]:
    values = channels[channel]
    return values["source"], values["medium"]


def generate_users(
    settings: GeneratorSettings, rng: np.random.Generator
) -> pd.DataFrame:
    cfg = settings.config
    count = settings.scale["users"]
    start = datetime.fromisoformat(cfg["period"]["start_date"]).replace(tzinfo=JST)
    end = datetime.fromisoformat(cfg["period"]["end_date"]).replace(tzinfo=JST)
    total_seconds = int((end - start).total_seconds())
    registration_channels = weighted_choice(
        rng, cfg["users"]["registration_channels"], count
    )
    regions = weighted_choice(rng, cfg["users"]["regions"], count)
    ages = weighted_choice(rng, cfg["users"]["age_bands"], count)
    genders = weighted_choice(rng, cfg["users"]["genders"], count)
    created_at = fixed_timestamp(settings)
    rows = []
    for i in range(count):
        registration_at = (
            start + timedelta(seconds=int(rng.integers(0, total_seconds + 1)))
        ).astimezone(UTC)
        source, medium = registration_source(
            str(registration_channels[i]), cfg["channels"]
        )
        region = str(regions[i])
        prefecture = str(rng.choice(cfg["users"]["prefectures"][region]))
        rows.append(
            {
                "user_sk": i + 1,
                "user_id": stable_id("usr", i + 1),
                "registration_at": registration_at,
                "registration_channel": str(registration_channels[i]),
                "acquisition_source": source,
                "acquisition_medium": medium,
                "acquisition_campaign_id": None,
                "country": "Japan",
                "region": region,
                "prefecture": prefecture,
                "gender": str(genders[i]),
                "age_band": str(ages[i]),
                "membership_rank_current": "bronze",
                "first_order_at": None,
                "first_order_id": None,
                "created_at": created_at,
                "updated_at": created_at,
            }
        )
    return pd.DataFrame(rows)


def generate_products(
    settings: GeneratorSettings, rng: np.random.Generator
) -> pd.DataFrame:
    cfg = settings.config
    count = settings.scale["products"]
    categories = cfg["products"]["categories"]
    category_names = list(categories)
    start = date.fromisoformat(cfg["period"]["start_date"]) - timedelta(days=730)
    end = date.fromisoformat(cfg["period"]["end_date"])
    created_at = fixed_timestamp(settings)
    raw_prices = rng.lognormal(
        float(cfg["products"]["price_lognormal_mean"]),
        float(cfg["products"]["price_lognormal_sigma"]),
        count,
    )
    raw_prices = np.clip(
        raw_prices,
        float(cfg["products"]["min_price"]),
        float(cfg["products"]["max_price"]),
    )
    rows = []
    for i in range(count):
        category_l1 = category_names[i % len(category_names)]
        category_l2 = str(rng.choice(categories[category_l1]))
        list_price = money(round(raw_prices[i] / 10) * 10)
        cost_ratio = Decimal(
            str(
                rng.uniform(
                    cfg["products"]["cost_ratio_min"],
                    cfg["products"]["cost_ratio_max"],
                )
            )
        )
        launch_date = start + timedelta(
            days=int(rng.integers(0, (end - start).days + 1))
        )
        rows.append(
            {
                "product_sk": i + 1,
                "product_id": stable_id("prd", i + 1, 5),
                "product_name": f"{category_l2} Item {i + 1:04d}",
                "brand": f"Brand {i % int(cfg['products']['brands']) + 1:02d}",
                "category_l1": category_l1,
                "category_l2": category_l2,
                "list_price": list_price,
                "standard_cost": money(list_price * cost_ratio),
                "launch_date": launch_date,
                "is_active": True,
                "created_at": created_at,
                "updated_at": created_at,
            }
        )
    return pd.DataFrame(rows)


def generate_campaigns(
    settings: GeneratorSettings, rng: np.random.Generator
) -> pd.DataFrame:
    cfg = settings.config
    count = settings.scale["campaigns"]
    start = date.fromisoformat(cfg["period"]["start_date"])
    end = date.fromisoformat(cfg["period"]["end_date"])
    always_count = max(2, round(count * float(cfg["campaigns"]["always_on_ratio"])))
    created_at = fixed_timestamp(settings)
    rows = []
    seasonal_periods = cfg["seasonality"]["periods"]
    for i in range(count):
        medium = "cpc" if i % 2 == 0 else "paid_social"
        source = "google" if medium == "cpc" else "social"
        platform = "Google Ads" if medium == "cpc" else "Social Ads"
        if i < always_count:
            campaign_start, campaign_end, kind = start, end, "always_on"
        else:
            period = seasonal_periods[(i - always_count) % len(seasonal_periods)]
            campaign_start = date.fromisoformat(period["start"])
            campaign_end = date.fromisoformat(period["end"])
            kind = "seasonal"
        rows.append(
            {
                "campaign_id": stable_id("cmp", i + 1, 4),
                "campaign_name": f"{kind.replace('_', ' ').title()} {medium} {i + 1:02d}",
                "platform": platform,
                "source": source,
                "medium": medium,
                "campaign_type": kind,
                "start_date": campaign_start,
                "end_date": campaign_end,
                "is_paid": True,
                "created_at": created_at,
                "updated_at": created_at,
            }
        )
    return pd.DataFrame(rows)


def assign_user_acquisition_campaigns(
    users: pd.DataFrame,
    campaigns: pd.DataFrame,
    paid_media: Sequence[str],
    rng: np.random.Generator,
) -> pd.DataFrame:
    result = users.copy()
    values = []
    for row in result.itertuples():
        if row.acquisition_medium not in paid_media:
            values.append(None)
            continue
        registration_date = pd.Timestamp(row.registration_at).tz_convert(JST).date()
        values.append(
            active_campaign(campaigns, row.acquisition_medium, registration_date, rng)
        )
    result["acquisition_campaign_id"] = values
    return result


def generate_contents(
    settings: GeneratorSettings,
    products: pd.DataFrame,
    rng: np.random.Generator,
) -> pd.DataFrame:
    cfg = settings.config
    count = settings.scale["contents"]
    start = datetime.fromisoformat(cfg["period"]["start_date"]).replace(tzinfo=JST)
    end = datetime.fromisoformat(cfg["period"]["end_date"]).replace(tzinfo=JST)
    types = weighted_choice(rng, cfg["contents"]["types"], count)
    categories = products["category_l1"].drop_duplicates().tolist()
    created_at = fixed_timestamp(settings)
    rows = []
    for i in range(count):
        content_type = str(types[i])
        published_at = (
            start
            + timedelta(
                seconds=int(rng.integers(0, int((end - start).total_seconds()) + 1))
            )
        ).astimezone(UTC)
        category = str(rng.choice(categories))
        content_id = stable_id("cnt", i + 1, 5)
        rows.append(
            {
                "content_id": content_id,
                "title": f"{category} {content_type.upper()} Guide {i + 1:03d}",
                "content_type": content_type,
                "author": f"Author {i % int(cfg['contents']['authors']) + 1:02d}",
                "published_at": published_at,
                "content_group": f"{category} Stories",
                "target_category": category,
                "page_path": f"/content/{content_id}",
                "is_active": True,
                "created_at": created_at,
                "updated_at": created_at,
            }
        )
    return pd.DataFrame(rows)


def generate_identity_bridge(
    settings: GeneratorSettings,
    users: pd.DataFrame,
    rng: np.random.Generator,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    cfg = settings.config
    pseudo_count = settings.scale["pseudo_ids"]
    linked_count = min(
        pseudo_count,
        max(
            len(users),
            round(pseudo_count * float(cfg["users"]["linked_pseudo_ratio"])),
        ),
    )
    user_ids = users["user_id"].tolist()
    assignments = user_ids.copy()
    if linked_count > len(user_ids):
        assignments.extend(
            rng.choice(
                user_ids,
                size=linked_count - len(user_ids),
                replace=True,
            ).tolist()
        )
    rng.shuffle(assignments)
    registration_by_user = users.set_index("user_id")["registration_at"].to_dict()
    created_at = fixed_timestamp(settings)
    max_valid_from = datetime.combine(
        date.fromisoformat(cfg["period"]["end_date"]),
        time(23, 59, 59),
        tzinfo=JST,
    ).astimezone(UTC)
    bridge_rows = []
    pseudo_rows = []
    for i in range(pseudo_count):
        pseudo_id = stable_id("pid", i + 1, 8)
        user_id = assignments[i] if i < linked_count else None
        valid_from = None
        if user_id:
            valid_from = pd.Timestamp(registration_by_user[user_id]).to_pydatetime()
            valid_from += timedelta(
                days=int(rng.integers(0, cfg["users"]["login_delay_days_max"] + 1))
            )
            valid_from = min(valid_from, max_valid_from)
            bridge_rows.append(
                {
                    "user_pseudo_id": pseudo_id,
                    "user_id": user_id,
                    "valid_from": valid_from,
                    "valid_to": None,
                    "identity_source": "login",
                    "is_current": True,
                    "created_at": created_at,
                }
            )
        pseudo_rows.append(
            {
                "user_pseudo_id": pseudo_id,
                "linked_user_id": user_id,
                "identity_valid_from": valid_from,
            }
        )
    return pd.DataFrame(bridge_rows), pd.DataFrame(pseudo_rows)


def day_probabilities(settings: GeneratorSettings) -> Tuple[List[date], np.ndarray]:
    cfg = settings.config
    days = [ts.date() for ts in period_dates(settings)]
    weights = []
    for day in days:
        value = 1.0
        if day.weekday() >= 5:
            value *= float(cfg["seasonality"]["weekend"])
        if day.day in cfg["seasonality"]["payday_days"]:
            value *= float(cfg["seasonality"]["payday"])
        _, _, traffic, _ = sale_period_for(day, cfg)
        value *= traffic
        weights.append(value)
    probs = np.array(weights, dtype=float)
    return days, probs / probs.sum()


def random_local_time(rng: np.random.Generator, day: date) -> datetime:
    hour_weights = np.array(
        [
            0.004, 0.003, 0.002, 0.002, 0.003, 0.008,
            0.025, 0.055, 0.060, 0.040, 0.045, 0.055,
            0.065, 0.045, 0.038, 0.035, 0.038, 0.048,
            0.060, 0.080, 0.100, 0.105, 0.070, 0.017,
        ],
        dtype=float,
    )
    hour_weights /= hour_weights.sum()
    hour = int(rng.choice(np.arange(24), p=hour_weights))
    return datetime.combine(
        day,
        time(hour, int(rng.integers(0, 60)), int(rng.integers(0, 60))),
        tzinfo=JST,
    )


def select_from_map(
    rng: np.random.Generator, values: Mapping[str, float]
) -> str:
    return str(weighted_choice(rng, values, 1)[0])


def active_campaign(
    campaigns: pd.DataFrame, medium: str, day: date, rng: np.random.Generator
) -> Optional[str]:
    eligible = campaigns[
        (campaigns["medium"] == medium)
        & (campaigns["start_date"] <= day)
        & (campaigns["end_date"] >= day)
    ]
    if eligible.empty:
        return None
    return str(rng.choice(eligible["campaign_id"].to_numpy()))


def allocate_capped_extras(
    rng: np.random.Generator,
    count: int,
    weights: np.ndarray,
    current: np.ndarray,
    cap: int,
) -> np.ndarray:
    extras = np.zeros(len(current), dtype=np.int64)
    remaining = count
    available = current < cap
    while remaining > 0:
        if not available.any():
            raise ValueError("event_count_cap is too small for requested event total")
        probabilities = np.where(available, weights, 0.0)
        probabilities /= probabilities.sum()
        batch = rng.multinomial(remaining, probabilities)
        capacity = cap - current - extras
        accepted = np.minimum(batch, capacity)
        extras += accepted
        remaining -= int(accepted.sum())
        available = current + extras < cap
    return extras


def generate_sessions(
    settings: GeneratorSettings,
    pseudo: pd.DataFrame,
    users: pd.DataFrame,
    campaigns: pd.DataFrame,
    contents: pd.DataFrame,
    rng: np.random.Generator,
) -> pd.DataFrame:
    cfg = settings.config
    count = settings.scale["sessions"]
    pseudo_count = len(pseudo)
    visit_propensity = rng.gamma(shape=0.75, scale=1.0, size=pseudo_count)
    visit_propensity /= visit_propensity.sum()
    pseudo_indices = rng.choice(
        np.arange(pseudo_count), size=count, replace=True, p=visit_propensity
    )
    days, probabilities = day_probabilities(settings)
    chosen_days = rng.choice(np.array(days, dtype=object), size=count, p=probabilities)
    channel_names = weighted_choice(
        rng,
        {name: values["probability"] for name, values in cfg["channels"].items()},
        count,
    )
    devices = weighted_choice(rng, cfg["devices"], count)
    user_lookup = users.set_index("user_id").to_dict("index")
    contents_published = contents.sort_values("published_at")
    content_ids = contents_published["content_id"].tolist()
    content_publish = {
        row.content_id: pd.Timestamp(row.published_at).to_pydatetime()
        for row in contents_published.itertuples()
    }
    user_propensity = {
        user_id: float(value)
        for user_id, value in zip(
            users["user_id"],
            rng.lognormal(mean=0.0, sigma=0.8, size=len(users)),
        )
    }
    rows = []
    base_scores = np.empty(count, dtype=float)
    created_at = fixed_timestamp(settings)
    for i in range(count):
        pseudo_row = pseudo.iloc[int(pseudo_indices[i])]
        day = chosen_days[i]
        start_local = random_local_time(rng, day)
        start_at = start_local.astimezone(UTC)
        linked_user = pseudo_row["linked_user_id"]
        valid_from = pseudo_row["identity_valid_from"]
        user_id = None
        if pd.notna(linked_user) and pd.notna(valid_from):
            if start_at >= pd.Timestamp(valid_from).to_pydatetime():
                user_id = str(linked_user)
        if user_id:
            user = user_lookup[user_id]
            country, region = user["country"], user["region"]
            propensity = user_propensity[user_id]
        else:
            country = "Japan"
            region = select_from_map(rng, cfg["users"]["regions"])
            propensity = 0.65

        channel_name = str(channel_names[i])
        channel = cfg["channels"][channel_name]
        source, medium = channel["source"], channel["medium"]
        campaign_id = (
            active_campaign(campaigns, medium, day, rng)
            if medium in cfg["campaigns"]["paid_media"]
            else None
        )
        device = str(devices[i])
        browser = select_from_map(rng, cfg["browsers"][device])
        operating_system = select_from_map(rng, cfg["operating_system"][device])

        published = [
            cid
            for cid in content_ids
            if content_publish[cid] <= start_at
        ]
        landing_content_id = (
            str(rng.choice(published))
            if published and rng.random() < (0.45 if "social" in channel_name else 0.25)
            else None
        )
        landing_page = (
            f"/content/{landing_content_id}"
            if landing_content_id
            else str(rng.choice(["/", "/search", "/category", "/new-arrivals"]))
        )
        _, _, _, seasonal_conversion = sale_period_for(day, cfg)
        base_scores[i] = (
            rng.exponential(1.0)
            * propensity
            * float(channel["conversion_multiplier"])
            * float(cfg["device_conversion_multiplier"][device])
            * seasonal_conversion
        )
        rows.append(
            {
                "session_id": stable_id("ses", i + 1, 9),
                "session_date": day,
                "user_pseudo_id": pseudo_row["user_pseudo_id"],
                "user_id": user_id,
                "session_start_at": start_at,
                "session_end_at": start_at,
                "landing_page": landing_page,
                "landing_content_id": landing_content_id,
                "source": source,
                "medium": medium,
                "campaign_id": campaign_id,
                "device_category": device,
                "browser": browser,
                "operating_system": operating_system,
                "country": country,
                "region": region,
                "event_count": 0,
                "engagement_time_msec": 0,
                "is_engaged_session": rng.random()
                < float(cfg["funnel"]["engaged_session_ratio"]),
                "is_converted_session": False,
                "order_count": 0,
                "session_revenue": money(0),
                "created_at": created_at,
                "gen_score": base_scores[i],
                "gen_view_item": False,
                "gen_add_to_cart": False,
                "gen_begin_checkout": False,
                "gen_purchase": False,
            }
        )
    sessions = pd.DataFrame(rows)

    view_count = round(count * float(cfg["funnel"]["view_item_sessions_ratio"]))
    cart_count = round(count * float(cfg["funnel"]["add_to_cart_sessions_ratio"]))
    checkout_count = round(
        count * float(cfg["funnel"]["begin_checkout_sessions_ratio"])
    )
    purchase_count = settings.scale["purchase_sessions"]
    ordered = sessions.sort_values("gen_score", ascending=False).index.to_numpy()
    identified_ordered = (
        sessions[sessions["user_id"].notna()]
        .sort_values("gen_score", ascending=False)
        .index.to_numpy()
    )
    required_identified = identified_ordered[:purchase_count]
    required_set = set(required_identified.tolist())
    view_fill = np.array(
        [index for index in ordered if index not in required_set],
        dtype=int,
    )
    view_idx = np.concatenate(
        [required_identified, view_fill[: view_count - len(required_identified)]]
    )
    view_candidates = sessions.loc[view_idx].copy()
    identified_view = view_candidates[view_candidates["user_id"].notna()].sort_values(
        "gen_score", ascending=False
    )
    anonymous_view = view_candidates[view_candidates["user_id"].isna()].sort_values(
        "gen_score", ascending=False
    )
    cart_idx = np.concatenate(
        [
            identified_view.index.to_numpy()[:cart_count],
            anonymous_view.index.to_numpy()[
                : max(0, cart_count - len(identified_view))
            ],
        ]
    )[:cart_count]
    cart_candidates = sessions.loc[cart_idx].copy()
    identified_cart = cart_candidates[cart_candidates["user_id"].notna()].sort_values(
        "gen_score", ascending=False
    )
    anonymous_cart = cart_candidates[cart_candidates["user_id"].isna()].sort_values(
        "gen_score", ascending=False
    )
    checkout_idx = np.concatenate(
        [
            identified_cart.index.to_numpy()[:checkout_count],
            anonymous_cart.index.to_numpy()[
                : max(0, checkout_count - len(identified_cart))
            ],
        ]
    )[:checkout_count]
    eligible_purchase = sessions.loc[checkout_idx]
    eligible_purchase = eligible_purchase[eligible_purchase["user_id"].notna()]
    if len(eligible_purchase) < purchase_count:
        raise ValueError(
            "Not enough identified checkout sessions for the configured purchase_sessions; "
            "raise linked_pseudo_ratio or lower purchase_sessions"
        )
    purchase_idx = (
        eligible_purchase.sort_values("gen_score", ascending=False).index[:purchase_count]
    )
    sessions.loc[view_idx, "gen_view_item"] = True
    sessions.loc[cart_idx, "gen_add_to_cart"] = True
    sessions.loc[checkout_idx, "gen_begin_checkout"] = True
    sessions.loc[purchase_idx, "gen_purchase"] = True
    sessions.loc[purchase_idx, "is_converted_session"] = True
    return sessions


def product_probabilities(products: pd.DataFrame, exponent: float) -> np.ndarray:
    ranks = np.arange(1, len(products) + 1, dtype=float)
    values = 1.0 / np.power(ranks, exponent)
    return values / values.sum()


def generate_orders_and_items(
    settings: GeneratorSettings,
    sessions: pd.DataFrame,
    products: pd.DataFrame,
    rng: np.random.Generator,
) -> Tuple[pd.DataFrame, pd.DataFrame, Dict[str, List[str]], Dict[str, str]]:
    cfg = settings.config
    order_cfg = cfg["orders"]
    order_count = settings.scale["orders"]
    purchase_sessions = sessions[sessions["gen_purchase"]].copy()
    session_ids = purchase_sessions["session_id"].tolist()
    assigned = session_ids.copy()
    if order_count > len(assigned):
        extra_weights = purchase_sessions["gen_score"].to_numpy(dtype=float)
        extra_weights /= extra_weights.sum()
        assigned.extend(
            rng.choice(
                np.array(session_ids, dtype=object),
                size=order_count - len(assigned),
                replace=True,
                p=extra_weights,
            ).tolist()
        )
    session_lookup = sessions.set_index("session_id").to_dict("index")
    product_probs = product_probabilities(
        products, float(cfg["products"]["popularity_zipf_exponent"])
    )
    product_lookup = products.set_index("product_id").to_dict("index")
    product_ids = products["product_id"].to_numpy()
    line_values = np.array(
        [int(value) for value in order_cfg["line_count_probabilities"]], dtype=int
    )
    line_probs = np.array(
        list(order_cfg["line_count_probabilities"].values()), dtype=float
    )
    status_random = rng.random(order_count)
    line_counts = rng.choice(
        line_values,
        size=order_count,
        p=line_probs / line_probs.sum(),
    ).astype(int)
    target_lines = settings.scale["order_items"]
    line_delta = target_lines - int(line_counts.sum())
    while line_delta != 0:
        if line_delta > 0:
            eligible = np.flatnonzero(line_counts < int(order_cfg["max_lines"]))
            if len(eligible) == 0:
                raise ValueError("max_lines is too low for target order_items")
            chosen = int(rng.choice(eligible))
            line_counts[chosen] += 1
            line_delta -= 1
        else:
            eligible = np.flatnonzero(line_counts > 1)
            if len(eligible) == 0:
                raise ValueError("target order_items is below the minimum line count")
            chosen = int(rng.choice(eligible))
            line_counts[chosen] -= 1
            line_delta += 1
    cancel_cut = float(order_cfg["cancellation_ratio"])
    refund_cut = cancel_cut + float(order_cfg["full_refund_ratio"])
    created_at = fixed_timestamp(settings)
    period_end = datetime.combine(
        date.fromisoformat(cfg["period"]["end_date"]),
        time(23, 59, 59),
        tzinfo=JST,
    ).astimezone(UTC)
    order_rows: List[Dict[str, Any]] = []
    item_rows: List[Dict[str, Any]] = []
    orders_by_session: Dict[str, List[str]] = defaultdict(list)
    primary_product_by_session: Dict[str, str] = {}

    for i, session_id in enumerate(assigned):
        session = session_lookup[session_id]
        ordered_at = pd.Timestamp(session["session_start_at"]).to_pydatetime() + timedelta(
            minutes=int(rng.integers(5, 90))
        )
        ordered_at = min(ordered_at, period_end)
        session_end = pd.Timestamp(session["session_end_at"]).to_pydatetime()
        if ordered_at > session_end + timedelta(hours=2):
            ordered_at = session_end
        if status_random[i] < cancel_cut:
            status = "cancelled"
        elif status_random[i] < refund_cut:
            status = "refunded"
        else:
            status = "completed"
        order_id = stable_id("ord", i + 1, 8)
        line_count = int(line_counts[i])
        chosen_products = rng.choice(
            product_ids,
            size=line_count,
            replace=False,
            p=product_probs,
        )
        use_coupon = rng.random() < float(order_cfg["coupon_probability"])
        discount_rate = (
            Decimal(
                str(
                    rng.choice(
                        order_cfg["discount_rates"],
                        p=order_cfg["discount_rate_probabilities"],
                    )
                )
            )
            if use_coupon
            else Decimal("0")
        )
        gross_sales = money(0)
        discount_amount = money(0)
        item_net_sales = money(0)
        raw_cost = money(0)
        for line_number, product_id in enumerate(chosen_products, start=1):
            product = product_lookup[str(product_id)]
            quantity = (
                int(rng.integers(2, 5))
                if rng.random() < float(order_cfg["multi_quantity_probability"])
                else 1
            )
            unit_list_price = money(product["list_price"])
            unit_selling_price = money(unit_list_price * (Decimal("1") - discount_rate))
            unit_cost = money(product["standard_cost"])
            line_gross = money(unit_list_price * quantity)
            line_net = money(unit_selling_price * quantity)
            line_discount = money(line_gross - line_net)
            line_cost = money(unit_cost * quantity)
            line_profit = money(line_net - line_cost)
            item_rows.append(
                {
                    "order_item_id": f"{order_id}_{line_number:02d}",
                    "order_id": order_id,
                    "order_date": ordered_at.astimezone(JST).date(),
                    "product_id": str(product_id),
                    "quantity": quantity,
                    "unit_list_price": unit_list_price,
                    "unit_selling_price": unit_selling_price,
                    "unit_cost": unit_cost,
                    "item_gross_sales": line_gross,
                    "item_discount_amount": line_discount,
                    "item_net_sales": line_net,
                    "item_cost": line_cost,
                    "item_gross_profit": line_profit,
                    "created_at": created_at,
                }
            )
            gross_sales += line_gross
            discount_amount += line_discount
            item_net_sales += line_net
            raw_cost += line_cost
        tax_amount = money(item_net_sales * Decimal(order_cfg["tax_rate"]))
        shipping_amount = (
            money(0)
            if item_net_sales >= Decimal(order_cfg["free_shipping_threshold"])
            else money(order_cfg["shipping_fee"])
        )
        order_total = money(item_net_sales + tax_amount + shipping_amount)
        recognized_revenue = item_net_sales if status == "completed" else money(0)
        cost_of_goods = raw_cost if status == "completed" else money(0)
        gross_profit = money(recognized_revenue - cost_of_goods)
        order_rows.append(
            {
                "order_id": order_id,
                "user_id": session["user_id"],
                "session_id": session_id,
                "ordered_at": ordered_at,
                "order_date": ordered_at.astimezone(JST).date(),
                "order_status": status,
                "currency": cfg["currency"],
                "gross_sales": gross_sales,
                "discount_amount": discount_amount,
                "item_net_sales": item_net_sales,
                "tax_amount": tax_amount,
                "shipping_amount": shipping_amount,
                "order_total": order_total,
                "recognized_revenue": recognized_revenue,
                "cost_of_goods": cost_of_goods,
                "gross_profit": gross_profit,
                "coupon_code": f"SAVE{int(discount_rate * 100):02d}" if use_coupon else None,
                "is_first_order": False,
                "device_category": session["device_category"],
                "created_at": created_at,
                "updated_at": created_at,
            }
        )
        orders_by_session[session_id].append(order_id)
        primary_product_by_session.setdefault(session_id, str(chosen_products[0]))

    orders = pd.DataFrame(order_rows).sort_values(["user_id", "ordered_at", "order_id"])
    first_indices = (
        orders[orders["order_status"] == "completed"]
        .groupby("user_id", sort=False)
        .head(1)
        .index
    )
    orders.loc[first_indices, "is_first_order"] = True
    orders = orders.sort_values("order_id").reset_index(drop=True)
    items = pd.DataFrame(item_rows).sort_values("order_item_id").reset_index(drop=True)
    sorted_order_ids = (
        orders.sort_values(["session_id", "ordered_at", "order_id"])
        .groupby("session_id")["order_id"]
        .apply(list)
        .to_dict()
    )
    orders_by_session = defaultdict(list, sorted_order_ids)
    return orders, items, orders_by_session, primary_product_by_session


def update_session_order_metrics(
    settings: GeneratorSettings,
    sessions: pd.DataFrame,
    orders: pd.DataFrame,
    rng: np.random.Generator,
) -> pd.DataFrame:
    cfg = settings.config
    grouped = orders.groupby("session_id").agg(
        order_count=("order_id", "count"),
        session_revenue=("recognized_revenue", "sum"),
    )
    result = sessions.copy()
    result["order_count"] = result["session_id"].map(grouped["order_count"]).fillna(0).astype(int)
    result["session_revenue"] = result["session_id"].map(
        grouped["session_revenue"]
    ).map(lambda value: money(value) if pd.notna(value) else money(0))

    base_counts = (
        2
        + result["gen_view_item"].astype(int)
        + result["gen_add_to_cart"].astype(int)
        + result["gen_begin_checkout"].astype(int)
        + result["order_count"]
    ).to_numpy(dtype=np.int64)
    target = settings.scale["events"]
    extras_needed = target - int(base_counts.sum())
    weights = np.where(
        result["is_engaged_session"].to_numpy(dtype=bool),
        1.8,
        0.7,
    ) * (1.0 + result["gen_view_item"].to_numpy(dtype=int))
    extras = allocate_capped_extras(
        rng,
        extras_needed,
        weights,
        base_counts,
        int(cfg["funnel"]["event_count_cap"]),
    )
    result["event_count"] = base_counts + extras
    engagement = rng.lognormal(mean=10.8, sigma=0.65, size=len(result)).astype(np.int64)
    engagement = np.where(
        result["is_engaged_session"].to_numpy(dtype=bool),
        np.maximum(engagement, 10000),
        np.minimum(engagement, 9999),
    )
    result["engagement_time_msec"] = engagement
    durations = np.maximum(
        30,
        np.minimum(
            7200,
            result["event_count"].to_numpy(dtype=int) * rng.integers(10, 55, len(result)),
        ),
    )
    period_end = datetime.combine(
        date.fromisoformat(settings.config["period"]["end_date"]),
        time(23, 59, 59),
        tzinfo=JST,
    ).astimezone(UTC)
    generated_end = [
        min(
            pd.Timestamp(start).to_pydatetime() + timedelta(seconds=int(seconds)),
            period_end,
        )
        for start, seconds in zip(result["session_start_at"], durations)
    ]
    max_ordered_at = orders.groupby("session_id")["ordered_at"].max()
    result["session_end_at"] = [
        max(
            end,
            pd.Timestamp(max_ordered_at.get(session_id)).to_pydatetime()
            if pd.notna(max_ordered_at.get(session_id))
            else end,
        )
        for session_id, end in zip(result["session_id"], generated_end)
    ]
    return result


def update_users_and_rank_history(
    settings: GeneratorSettings,
    users: pd.DataFrame,
    orders: pd.DataFrame,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    cfg = settings.config
    completed = orders[orders["order_status"] == "completed"].sort_values(
        ["user_id", "ordered_at", "order_id"]
    )
    result = users.copy()
    first = completed.groupby("user_id", sort=False).first()
    result["first_order_at"] = result["user_id"].map(first["ordered_at"])
    result["first_order_id"] = result["user_id"].map(first["order_id"])
    created_at = fixed_timestamp(settings)
    end_exclusive = date.fromisoformat(cfg["period"]["end_date"]) + timedelta(days=1)
    histories: List[Dict[str, Any]] = []
    current_by_user: Dict[str, str] = {}
    thresholds = cfg["membership"]["thresholds"]
    rank_order = cfg["membership"]["ranks"]
    order_groups = {
        user_id: group
        for user_id, group in completed.groupby("user_id", sort=False)
    }
    for user in result.itertuples():
        transitions = [(pd.Timestamp(user.registration_at).date(), "bronze")]
        user_orders = order_groups.get(user.user_id, completed.iloc[0:0])
        running_orders = 0
        running_revenue = Decimal("0")
        current_rank = "bronze"
        daily = user_orders.groupby("order_date").agg(
            orders=("order_id", "count"),
            revenue=("recognized_revenue", "sum"),
        )
        for order_date, values in daily.iterrows():
            running_orders += int(values["orders"])
            running_revenue += Decimal(str(values["revenue"]))
            candidate = "bronze"
            for rank in rank_order[1:]:
                rule = thresholds[rank]
                if (
                    running_orders >= int(rule["orders"])
                    or running_revenue >= Decimal(str(rule["revenue"]))
                ):
                    candidate = rank
            if candidate != current_rank:
                if transitions[-1][0] == order_date:
                    transitions[-1] = (order_date, candidate)
                else:
                    transitions.append((order_date, candidate))
                current_rank = candidate
        for index, (valid_from, rank) in enumerate(transitions):
            valid_to = (
                transitions[index + 1][0]
                if index + 1 < len(transitions)
                else None
            )
            histories.append(
                {
                    "user_id": user.user_id,
                    "membership_rank": rank,
                    "valid_from": valid_from,
                    "valid_to": valid_to,
                    "is_current": valid_to is None,
                    "created_at": created_at,
                }
            )
        current_by_user[user.user_id] = current_rank
    result["membership_rank_current"] = result["user_id"].map(current_by_user)
    result["updated_at"] = created_at
    history = pd.DataFrame(histories).sort_values(["user_id", "valid_from"])
    return result, history


def event_page_values(
    event_name: str,
    session: Any,
    product_id: Optional[str],
    content_lookup: Dict[str, Dict[str, Any]],
) -> Tuple[
    Optional[str],
    Optional[str],
    Optional[str],
    Optional[str],
    Optional[str],
]:
    if event_name == "session_start":
        return session.landing_page, session.landing_page, "Session start", None, None
    content_id = session.landing_content_id
    if content_id and event_name == "page_view":
        content = content_lookup[content_id]
        return (
            f"https://portfolio.example{content['page_path']}",
            content["page_path"],
            content["title"],
            content_id,
            content["content_group"],
        )
    if product_id and event_name in {
        "view_item",
        "add_to_cart",
        "begin_checkout",
        "purchase",
    }:
        path = f"/products/{product_id}"
        return f"https://portfolio.example{path}", path, "Product detail", None, None
    return (
        f"https://portfolio.example{session.landing_page}",
        session.landing_page,
        "EC Portfolio",
        None,
        None,
    )


def write_events(
    settings: GeneratorSettings,
    writer: RawTableWriter,
    sessions: pd.DataFrame,
    orders: pd.DataFrame,
    orders_by_session: Dict[str, List[str]],
    primary_product_by_session: Dict[str, str],
    products: pd.DataFrame,
    contents: pd.DataFrame,
    rng: np.random.Generator,
) -> Dict[str, int]:
    product_ids = products["product_id"].to_numpy()
    product_probs = product_probabilities(
        products, float(settings.config["products"]["popularity_zipf_exponent"])
    )
    content_lookup = contents.set_index("content_id").to_dict("index")
    order_lookup = orders.set_index("order_id").to_dict("index")
    event_counts: Dict[str, int] = defaultdict(int)
    event_number = 0
    created_at = fixed_timestamp(settings)
    with writer.stream("fact_events") as output:
        for session in sessions.sort_values("session_id").itertuples():
            primary_product = primary_product_by_session.get(session.session_id)
            if primary_product is None and session.gen_view_item:
                primary_product = str(rng.choice(product_ids, p=product_probs))
            names = ["session_start", "page_view"]
            mandatory_after = (
                int(session.gen_view_item)
                + int(session.gen_add_to_cart)
                + int(session.gen_begin_checkout)
                + int(session.order_count)
            )
            extra_views = int(session.event_count) - 2 - mandatory_after
            names.extend(["page_view"] * extra_views)
            if session.gen_view_item:
                names.append("view_item")
            if session.gen_add_to_cart:
                names.append("add_to_cart")
            if session.gen_begin_checkout:
                names.append("begin_checkout")
            names.extend(["purchase"] * int(session.order_count))
            if len(names) != int(session.event_count):
                raise AssertionError("Generated event list does not match fact_sessions.event_count")

            session_order_ids = orders_by_session.get(session.session_id, [])
            purchase_times = [
                pd.Timestamp(order_lookup[order_id]["ordered_at"]).to_pydatetime()
                for order_id in session_order_ids
            ]
            browse_end = (
                purchase_times[0]
                if purchase_times
                else pd.Timestamp(session.session_end_at).to_pydatetime()
            )
            browse_duration = max(
                1,
                int(
                    (
                        pd.Timestamp(browse_end)
                        - pd.Timestamp(session.session_start_at)
                    ).total_seconds()
                ),
            )
            non_purchase_count = len(names) - len(session_order_ids)
            purchase_order_ids = iter(session_order_ids)
            for sequence, event_name in enumerate(names, start=1):
                event_number += 1
                offset = round(
                    (sequence - 1)
                    * max(0, browse_duration - 1)
                    / max(1, non_purchase_count - 1)
                )
                event_timestamp = (
                    pd.Timestamp(session.session_start_at).to_pydatetime()
                    + timedelta(seconds=offset)
                )
                order_id = next(purchase_order_ids) if event_name == "purchase" else None
                if order_id:
                    event_timestamp = order_lookup[order_id]["ordered_at"]
                product_id = (
                    primary_product
                    if event_name in {
                        "view_item",
                        "add_to_cart",
                        "begin_checkout",
                        "purchase",
                    }
                    else None
                )
                page_location, page_path, page_title, content_id, content_group = (
                    event_page_values(
                        event_name,
                        session,
                        product_id,
                        content_lookup,
                    )
                )
                engagement = (
                    int(session.engagement_time_msec) // int(session.event_count)
                    if event_name not in {"session_start", "purchase"}
                    else 0
                )
                output.writerow(
                    {
                        "event_id": stable_id("evt", event_number, 10),
                        "event_date": event_timestamp.astimezone(JST).date(),
                        "event_timestamp": event_timestamp,
                        "event_name": event_name,
                        "user_pseudo_id": session.user_pseudo_id,
                        "user_id": session.user_id,
                        "session_id": session.session_id,
                        "event_sequence": sequence,
                        "page_location": page_location,
                        "page_path": page_path,
                        "page_title": page_title,
                        "content_id": content_id,
                        "content_group": content_group,
                        "product_id": product_id,
                        "order_id": order_id,
                        "source": session.source,
                        "medium": session.medium,
                        "campaign_id": session.campaign_id,
                        "device_category": session.device_category,
                        "browser": session.browser,
                        "operating_system": session.operating_system,
                        "country": session.country,
                        "region": session.region,
                        "engagement_time_msec": engagement,
                        "is_engaged_session": session.is_engaged_session,
                        "is_conversion_event": event_name == "purchase",
                        "created_at": created_at,
                    }
                )
                event_counts[event_name] += 1
    if event_number != settings.scale["events"]:
        raise AssertionError(
            f"Expected {settings.scale['events']} events, generated {event_number}"
        )
    return dict(event_counts)


def generate_campaign_costs(
    settings: GeneratorSettings,
    campaigns: pd.DataFrame,
    rng: np.random.Generator,
) -> pd.DataFrame:
    cfg = settings.config
    rows = []
    created_at = fixed_timestamp(settings)
    for campaign in campaigns.itertuples():
        for day in pd.date_range(campaign.start_date, campaign.end_date, freq="D"):
            ctr_low, ctr_high = (
                cfg["campaigns"]["search_ctr_range"]
                if campaign.medium == "cpc"
                else cfg["campaigns"]["social_ctr_range"]
            )
            impressions = int(max(100, rng.lognormal(mean=7.2, sigma=0.55)))
            ctr = float(rng.uniform(ctr_low, ctr_high))
            clicks = min(impressions, int(round(impressions * ctr)))
            cpc = rng.lognormal(
                mean=float(cfg["campaigns"]["cpc_lognormal_mean"]),
                sigma=float(cfg["campaigns"]["cpc_lognormal_sigma"]),
            )
            budget = rng.uniform(*cfg["campaigns"]["daily_budget_range"])
            cost_value = money(min(clicks * cpc, budget))
            rows.append(
                {
                    "cost_date": day.date(),
                    "campaign_id": campaign.campaign_id,
                    "platform": campaign.platform,
                    "source": campaign.source,
                    "medium": campaign.medium,
                    "impressions": impressions,
                    "clicks": clicks,
                    "cost": cost_value,
                    "currency": cfg["currency"],
                    "created_at": created_at,
                }
            )
    return pd.DataFrame(rows)


def allocate_decimal_total(total: Decimal, count: int, scale: Decimal) -> List[Decimal]:
    if count <= 0:
        return []
    each = (total / count).quantize(scale, rounding=ROUND_HALF_UP)
    values = [each] * count
    values[-1] += total - sum(values, Decimal("0"))
    return values


def generate_touchpoints(
    settings: GeneratorSettings,
    sessions: pd.DataFrame,
    orders: pd.DataFrame,
) -> pd.DataFrame:
    cfg = settings.config
    lookback = int(cfg["attribution"]["lookback_days"])
    direct_source = cfg["attribution"]["direct_source"]
    direct_medium = cfg["attribution"]["direct_medium"]
    created_at = fixed_timestamp(settings)
    sessions_by_user = {
        user_id: group.sort_values("session_start_at")
        for user_id, group in sessions[sessions["user_id"].notna()].groupby("user_id")
    }
    rows: List[Dict[str, Any]] = []
    for order in orders.sort_values(["ordered_at", "order_id"]).itertuples():
        candidates = sessions_by_user.get(order.user_id)
        if candidates is None:
            continue
        start = pd.Timestamp(order.ordered_at) - pd.Timedelta(days=lookback)
        eligible = candidates[
            (candidates["session_start_at"] >= start)
            & (candidates["session_start_at"] <= pd.Timestamp(order.ordered_at))
        ].drop_duplicates("session_id")
        if eligible.empty:
            continue
        eligible = eligible.sort_values("session_start_at")
        non_direct = eligible[
            ~(
                (eligible["source"] == direct_source)
                & (eligible["medium"] == direct_medium)
            )
        ]
        last_touch_session = (
            non_direct.iloc[-1]["session_id"]
            if not non_direct.empty
            else eligible.iloc[-1]["session_id"]
        )
        linear_credits = allocate_decimal_total(
            Decimal("1.000000"), len(eligible), CREDIT
        )
        linear_revenue = allocate_decimal_total(
            money(order.recognized_revenue), len(eligible), MONEY
        )
        for sequence, (_, touch) in enumerate(eligible.iterrows(), start=1):
            is_last_credit = touch["session_id"] == last_touch_session
            rows.append(
                {
                    "order_id": order.order_id,
                    "order_date": order.order_date,
                    "touchpoint_timestamp": touch["session_start_at"],
                    "session_id": touch["session_id"],
                    "touchpoint_sequence": sequence,
                    "source": touch["source"],
                    "medium": touch["medium"],
                    "campaign_id": touch["campaign_id"],
                    "content_id": touch["landing_content_id"],
                    "days_before_purchase": max(
                        0,
                        (
                            pd.Timestamp(order.ordered_at).date()
                            - pd.Timestamp(touch["session_start_at"]).date()
                        ).days,
                    ),
                    "is_first_touch": sequence == 1,
                    "is_last_touch": sequence == len(eligible),
                    "last_touch_credit": Decimal("1.000000")
                    if is_last_credit
                    else Decimal("0.000000"),
                    "linear_credit": linear_credits[sequence - 1],
                    "attributed_revenue_last_touch": money(order.recognized_revenue)
                    if is_last_credit
                    else money(0),
                    "attributed_revenue_linear": linear_revenue[sequence - 1],
                    "created_at": created_at,
                }
            )
    return pd.DataFrame(rows)


def generate_all(
    settings: GeneratorSettings,
    writer: RawTableWriter,
) -> Dict[str, Any]:
    rng = np.random.default_rng(int(settings.config["seed"]))
    table_names = list(settings.contract["tables"])
    writer.prepare(table_names)

    dim_date = generate_dim_date(settings)
    users = generate_users(settings, rng)
    products = generate_products(settings, rng)
    campaigns = generate_campaigns(settings, rng)
    users = assign_user_acquisition_campaigns(
        users,
        campaigns,
        settings.config["campaigns"]["paid_media"],
        rng,
    )
    contents = generate_contents(settings, products, rng)
    bridge, pseudo = generate_identity_bridge(settings, users, rng)
    sessions = generate_sessions(
        settings, pseudo, users, campaigns, contents, rng
    )
    orders, items, orders_by_session, primary_products = generate_orders_and_items(
        settings, sessions, products, rng
    )
    sessions = update_session_order_metrics(settings, sessions, orders, rng)
    users, membership_history = update_users_and_rank_history(settings, users, orders)
    campaign_costs = generate_campaign_costs(settings, campaigns, rng)
    touchpoints = generate_touchpoints(settings, sessions, orders)

    frames = {
        "dim_date": dim_date,
        "dim_users": users,
        "dim_membership_rank_history": membership_history,
        "bridge_user_identity": bridge,
        "dim_products": products,
        "dim_campaign": campaigns,
        "dim_content": contents,
        "fact_orders": orders,
        "fact_order_items": items,
        "fact_sessions": sessions[
            writer.columns("fact_sessions")
        ].copy(),
        "fact_campaign_cost_daily": campaign_costs,
        "int_order_touchpoints": touchpoints,
    }
    for table, frame in frames.items():
        writer.write_frame(table, frame)

    event_counts = write_events(
        settings,
        writer,
        sessions,
        orders,
        orders_by_session,
        primary_products,
        products,
        contents,
        rng,
    )
    return {
        "scale": settings.scale_name,
        "seed": settings.config["seed"],
        "event_counts": event_counts,
        "expected_rows": {
            table: (
                settings.scale["events"]
                if table == "fact_events"
                else len(frame)
            )
            for table, frame in frames.items()
        }
        | {"fact_events": settings.scale["events"]},
    }
