from __future__ import annotations

import csv
import gzip
import json
import shutil
from contextlib import contextmanager
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any, Dict, Iterable, Iterator, List

import pandas as pd


def serialize_value(value: Any) -> Any:
    if value is None or value is pd.NA:
        return ""
    try:
        if bool(pd.isna(value)):
            return ""
    except (TypeError, ValueError):
        pass
    if isinstance(value, (datetime, pd.Timestamp)):
        timestamp = pd.Timestamp(value)
        if timestamp.tzinfo is not None:
            timestamp = timestamp.tz_convert("UTC").tz_localize(None)
        return timestamp.isoformat(timespec="seconds") + "Z"
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, Decimal):
        return format(value, "f")
    if isinstance(value, bool):
        return "true" if value else "false"
    return value


class RawTableWriter:
    def __init__(self, output_root: Path, contract: Dict[str, Any], overwrite: bool):
        self.output_root = output_root
        self.contract = contract
        self.overwrite = overwrite

    def columns(self, table: str) -> List[str]:
        return list(self.contract["tables"][table]["columns"].keys())

    def path_for(self, table: str) -> Path:
        return self.output_root / table / "part-00000.csv.gz"

    def prepare(self, tables: Iterable[str]) -> None:
        table_list = list(tables)
        existing = [
            self.output_root / table
            for table in table_list
            if (self.output_root / table).exists()
        ]
        if existing and not self.overwrite:
            display = ", ".join(str(path) for path in existing[:5])
            raise FileExistsError(
                f"Generated table directories already exist ({display}); "
                "pass --overwrite to replace all generated tables"
            )
        for table in table_list:
            table_dir = self.output_root / table
            if table_dir.exists():
                shutil.rmtree(table_dir)
            table_dir.mkdir(parents=True, exist_ok=False)

    def write_frame(self, table: str, frame: pd.DataFrame) -> Path:
        expected = self.columns(table)
        missing = sorted(set(expected) - set(frame.columns))
        extra = sorted(set(frame.columns) - set(expected))
        if missing or extra:
            raise ValueError(f"{table} schema mismatch: missing={missing}, extra={extra}")
        path = self.path_for(table)
        serial = frame.loc[:, expected].copy()
        for column in expected:
            serial[column] = serial[column].map(serialize_value)
        serial.to_csv(path, index=False, compression="gzip", lineterminator="\n")
        return path

    @contextmanager
    def stream(self, table: str) -> Iterator[csv.DictWriter]:
        path = self.path_for(table)
        columns = self.columns(table)
        with gzip.open(path, "wt", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(
                handle,
                fieldnames=columns,
                extrasaction="raise",
                lineterminator="\n",
            )
            writer.writeheader()

            class SerializingWriter:
                def writerow(self, row: Dict[str, Any]) -> None:
                    writer.writerow({key: serialize_value(row.get(key)) for key in columns})

                def writerows(self, rows: Iterable[Dict[str, Any]]) -> None:
                    for row in rows:
                        self.writerow(row)

            yield SerializingWriter()  # type: ignore[misc]


def write_json(path: Path, value: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, default=serialize_value) + "\n",
        encoding="utf-8",
    )
