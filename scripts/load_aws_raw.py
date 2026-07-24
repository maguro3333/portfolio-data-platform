#!/usr/bin/env python3
"""Upload generated CSV.gz to S3 and (re)create Athena raw external tables.

Mirrors the GCP raw load: every column is STRING (OpenCSVSerde), and dbt
staging casts from string, so DuckDB / BigQuery / Athena share one staging
contract. OpenCSVSerde handles quoted fields and reads gzip automatically.
"""
from __future__ import annotations

import gzip
import os
import sys
import time
from pathlib import Path

import boto3

REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
DATA_BUCKET = os.environ.get("DATA_BUCKET", "ec-portfolio-052223515273-data")
RAW_DB = os.environ.get("RAW_DB", "ec_raw")
WORKGROUP = os.environ.get("ATHENA_WORKGROUP", "ec_portfolio")
RAW_DIR = Path(os.environ.get("RAW_DIR", "data/raw"))

s3 = boto3.client("s3", region_name=REGION)
athena = boto3.client("athena", region_name=REGION)


def header_columns(csv_gz: Path) -> list[str]:
    with gzip.open(csv_gz, "rt") as fh:
        return [c.strip() for c in fh.readline().rstrip("\n").split(",")]


def run_athena(sql: str) -> None:
    qid = athena.start_query_execution(
        QueryString=sql,
        QueryExecutionContext={"Database": RAW_DB},
        WorkGroup=WORKGROUP,
    )["QueryExecutionId"]
    while True:
        st = athena.get_query_execution(QueryExecutionId=qid)["QueryExecution"]["Status"]
        state = st["State"]
        if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
            if state != "SUCCEEDED":
                raise RuntimeError(f"Athena {state}: {st.get('StateChangeReason')}\nSQL: {sql[:200]}")
            return
        time.sleep(1)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    os.chdir(root)

    for table_dir in sorted(RAW_DIR.iterdir()):
        if not table_dir.is_dir():
            continue
        table = table_dir.name
        files = sorted(table_dir.glob("*.csv.gz"))
        if not files:
            continue

        print(f">>> {table}: upload")
        for f in files:
            s3.upload_file(str(f), DATA_BUCKET, f"raw/{table}/{f.name}")

        cols = header_columns(files[0])
        col_ddl = ",\n  ".join(f"`{c}` string" for c in cols)
        location = f"s3://{DATA_BUCKET}/raw/{table}/"
        print(f">>> {table}: create external table {RAW_DB}.{table}")
        run_athena(f"DROP TABLE IF EXISTS `{table}`")
        run_athena(
            f"CREATE EXTERNAL TABLE `{table}` (\n  {col_ddl}\n)\n"
            "ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'\n"
            "WITH SERDEPROPERTIES ('separatorChar'=',','quoteChar'='\"')\n"
            f"STORED AS TEXTFILE\nLOCATION '{location}'\n"
            "TBLPROPERTIES ('skip.header.line.count'='1')"
        )

    print(f"All raw external tables created in {RAW_DB}.")


if __name__ == "__main__":
    sys.exit(main())
