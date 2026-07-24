#!/usr/bin/env bash
# Upload generated CSV.gz to GCS and load into BigQuery ec_raw as ALL-STRING
# tables. Staging (dbt) casts from string, mirroring the local duckdb path
# (read_csv all_varchar=true) so both targets produce identical results.
# Note: no `pipefail` — the `gzip -dc | head -1` header read intentionally
# closes the pipe early (SIGPIPE on gzip), which pipefail would treat as fatal.
set -eu

PROJECT="${GCP_PROJECT:-psyched-camp-502314-m3}"
BUCKET="${RAW_BUCKET:-psyched-camp-502314-m3-ec-raw}"
DATASET="${RAW_DATASET:-ec_raw}"
RAW_DIR="${RAW_DIR:-data/raw}"

cd "$(dirname "$0")/.."

for dir in "$RAW_DIR"/*/; do
  table="$(basename "$dir")"
  file="$(ls "$dir"*.csv.gz | head -1)"

  echo ">>> ${table}: upload"
  gsutil -q cp "$dir"*.csv.gz "gs://${BUCKET}/raw/${table}/"

  # Build an all-STRING schema from the header row.
  header="$(gzip -dc "$file" | head -1)"
  schema="$(printf '%s' "$header" | tr ',' '\n' | sed 's/[[:space:]]*$//; s/$/:STRING/' | paste -sd, -)"

  echo ">>> ${table}: load -> ${PROJECT}:${DATASET}.${table}"
  bq --project_id="$PROJECT" load \
    --replace \
    --source_format=CSV \
    --skip_leading_rows=1 \
    --allow_quoted_newlines \
    "${DATASET}.${table}" \
    "gs://${BUCKET}/raw/${table}/*.csv.gz" \
    "$schema"
done

echo "All raw tables loaded into ${PROJECT}:${DATASET}."
