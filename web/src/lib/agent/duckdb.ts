"use client";

import type * as DuckDB from "@duckdb/duckdb-wasm";

const PUBLIC_MARTS = [
  "mart_content_assists",
  "mart_content_performance",
  "mart_customer_cohort",
  "mart_funnel_daily",
  "mart_kpi_daily",
  "mart_marketing_daily",
  "mart_rfm_segment_daily",
] as const;

const QUERY_ROW_LIMIT = 1_000;
const RESPONSE_ROW_LIMIT = 50;

type JsonValue =
  | string
  | number
  | boolean
  | null
  | JsonValue[]
  | { [key: string]: JsonValue };

export type QueryRow = Record<string, JsonValue>;

export type QueryResult = {
  rows: QueryRow[];
  returnedRows: number;
  truncated: boolean;
};

let databasePromise: Promise<DuckDB.AsyncDuckDB> | undefined;

function serializeValue(value: unknown): JsonValue {
  if (value === null || value === undefined) {
    return null;
  }
  if (typeof value === "bigint") {
    return value.toString();
  }
  if (
    typeof value === "string" ||
    typeof value === "number" ||
    typeof value === "boolean"
  ) {
    return value;
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (Array.isArray(value)) {
    return value.map(serializeValue);
  }
  if (typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, item]) => [
        key,
        serializeValue(item),
      ]),
    );
  }
  return String(value);
}

function serializeRow(row: unknown): QueryRow {
  const record =
    typeof row === "object" && row !== null && "toJSON" in row
      ? (row as { toJSON: () => Record<string, unknown> }).toJSON()
      : (row as Record<string, unknown>);

  return Object.fromEntries(
    Object.entries(record).map(([key, value]) => [key, serializeValue(value)]),
  );
}

async function initializeDuckDb() {
  const duckdb = await import("@duckdb/duckdb-wasm");
  const bundle = await duckdb.selectBundle(duckdb.getJsDelivrBundles());
  if (!bundle.mainWorker) {
    throw new Error("このブラウザで利用できるDuckDB Workerが見つかりません。");
  }

  const worker = new Worker(bundle.mainWorker);
  const logger = new duckdb.ConsoleLogger(duckdb.LogLevel.WARNING);
  const db = new duckdb.AsyncDuckDB(logger, worker);

  try {
    await db.instantiate(bundle.mainModule, bundle.pthreadWorker);

    await Promise.all(
      PUBLIC_MARTS.map(async (mart) => {
        const fileName = `${mart}.parquet`;
        const response = await fetch(`/marts/${fileName}`, {
          cache: "force-cache",
        });
        if (!response.ok) {
          throw new Error(`${fileName}を読み込めませんでした。`);
        }
        await db.registerFileBuffer(
          fileName,
          new Uint8Array(await response.arrayBuffer()),
        );
      }),
    );

    const connection = await db.connect();
    try {
      for (const mart of PUBLIC_MARTS) {
        await connection.query(
          `CREATE VIEW "${mart}" AS SELECT * FROM parquet_scan('${mart}.parquet')`,
        );
      }
    } finally {
      await connection.close();
    }
    return db;
  } catch (error) {
    await db.terminate();
    throw error;
  }
}

export function getBrowserDuckDb() {
  if (!databasePromise) {
    databasePromise = initializeDuckDb().catch((error) => {
      databasePromise = undefined;
      throw error;
    });
  }
  return databasePromise;
}

export async function runBrowserQuery(sql: string): Promise<QueryResult> {
  const normalizedSql = sql.trim().replace(/;\s*$/, "");
  const limitedSql = `SELECT * FROM (${normalizedSql}) AS agent_result LIMIT ${QUERY_ROW_LIMIT + 1}`;
  const db = await getBrowserDuckDb();
  const connection = await db.connect();

  try {
    const result = await connection.query(limitedSql);
    const allRows = result.toArray().map(serializeRow);
    return {
      rows: allRows.slice(0, RESPONSE_ROW_LIMIT),
      returnedRows: Math.min(allRows.length, QUERY_ROW_LIMIT),
      truncated: allRows.length > RESPONSE_ROW_LIMIT,
    };
  } finally {
    await connection.close();
  }
}
