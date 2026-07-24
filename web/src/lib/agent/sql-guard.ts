export const ALLOWED_MARTS = [
  "mart_content_assists",
  "mart_content_performance",
  "mart_customer_cohort",
  "mart_funnel_daily",
  "mart_kpi_daily",
  "mart_marketing_daily",
  "mart_rfm_segment_daily",
] as const;

const ALLOWED_MART_SET = new Set<string>(ALLOWED_MARTS);

const FORBIDDEN_KEYWORDS = [
  "insert",
  "update",
  "delete",
  "merge",
  "create",
  "drop",
  "alter",
  "truncate",
  "attach",
  "detach",
  "copy",
  "pragma",
  "install",
  "load",
  "call",
  "export",
  "import",
  "vacuum",
  "set",
  "reset",
  "checkpoint",
  "force",
] as const;

const FORBIDDEN_ACCESS_PATTERNS = [
  /\bread_(?:csv|json|parquet|text|blob)(?:_auto)?\b/i,
  /\bparquet_(?:scan|metadata|schema|file_metadata)\b/i,
  /\bcsv_scan\b/i,
  /\bsniff_csv\b/i,
  /\bglob\s*\(/i,
  /\bhttpfs\b/i,
  /\binformation_schema\b/i,
  /\bduckdb_[a-z0-9_]*\b/i,
  /\bsqlite_[a-z0-9_]*\b/i,
  /\bgetenv\s*\(/i,
  /\bcurrent_setting\s*\(/i,
  /\bquery(?:_table)?\s*\(/i,
  /\bfrom\s+'/i,
] as const;

export class UnsafeSqlError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "UnsafeSqlError";
  }
}

function removeComments(sql: string) {
  return sql
    .replace(/\/\*[\s\S]*?\*\//g, " ")
    .replace(/--[^\r\n]*/g, " ");
}

function maskStringLiterals(sql: string) {
  return sql.replace(/'(?:''|[^'])*'/g, "''");
}

function normalizeIdentifier(identifier: string) {
  return identifier.replace(/^["`]|["`]$/g, "").toLowerCase();
}

function extractCteNames(sql: string) {
  const ctes = new Set<string>();
  const pattern = /(?:\bwith\b|,)\s*(["`]?[a-z_][a-z0-9_]*["`]?)\s+as\s*\(/gi;
  for (const match of sql.matchAll(pattern)) {
    ctes.add(normalizeIdentifier(match[1]));
  }
  return ctes;
}

function validateTableReferences(sql: string) {
  const ctes = extractCteNames(sql);
  const tablePattern = /\b(?:from|join)\s+(["`]?[a-z_][a-z0-9_]*["`]?)/gi;

  for (const match of sql.matchAll(tablePattern)) {
    const table = normalizeIdentifier(match[1]);
    if (!ALLOWED_MART_SET.has(table) && !ctes.has(table)) {
      throw new UnsafeSqlError(
        `参照可能なテーブルは公開martのみです: ${table}`,
      );
    }
  }
}

export function validateReadOnlySql(input: string) {
  const sql = input.trim();
  if (!sql) {
    throw new UnsafeSqlError("SQLが空です。");
  }
  if (sql.length > 20_000) {
    throw new UnsafeSqlError("SQLが長すぎます。");
  }

  const withoutComments = removeComments(sql);
  const masked = maskStringLiterals(withoutComments).trim();

  if (!/^(select|with)\b/i.test(masked)) {
    throw new UnsafeSqlError("SELECTまたはWITHで始まるSQLだけを実行できます。");
  }

  const semicolonPositions = [...masked.matchAll(/;/g)].map(
    (match) => match.index ?? -1,
  );
  if (
    semicolonPositions.length > 1 ||
    (semicolonPositions.length === 1 &&
      masked.slice(semicolonPositions[0] + 1).trim() !== "")
  ) {
    throw new UnsafeSqlError("複数のSQL文は実行できません。");
  }

  for (const keyword of FORBIDDEN_KEYWORDS) {
    if (new RegExp(`\\b${keyword}\\b`, "i").test(masked)) {
      throw new UnsafeSqlError(`許可されていないSQL操作です: ${keyword}`);
    }
  }

  for (const pattern of FORBIDDEN_ACCESS_PATTERNS) {
    if (pattern.test(masked)) {
      throw new UnsafeSqlError("外部ファイルやsystem tableは参照できません。");
    }
  }

  validateTableReferences(masked);
  return sql.replace(/;\s*$/, "");
}
