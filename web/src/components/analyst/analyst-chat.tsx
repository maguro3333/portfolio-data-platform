"use client";

import { FormEvent, useState } from "react";
import {
  runBrowserQuery,
  type QueryResult,
  type QueryRow,
} from "@/lib/agent/duckdb";

type TextBlock = {
  type: "text";
  text: string;
};

type ToolUseBlock = {
  type: "tool_use";
  id: string;
  name: string;
  input: unknown;
};

type AssistantBlock = TextBlock | ToolUseBlock;

type ToolResultBlock = {
  type: "tool_result";
  tool_use_id: string;
  content: string;
  is_error?: boolean;
};

type AgentMessage = {
  role: "user" | "assistant";
  content: string | AssistantBlock[] | ToolResultBlock[];
};

type ValidatedToolUse = {
  toolUseId: string;
  sql: string;
  valid: boolean;
  reason: string | null;
};

type ProxyResponse = {
  assistantContent?: AssistantBlock[];
  stopReason?: string | null;
  toolUses?: ValidatedToolUse[];
  error?: string;
  code?: string;
};

type AnalystResult = QueryResult & {
  answer: string;
  sql: string | null;
};

const MAX_TOOL_ROUNDS = 5;

const sampleQuestions = [
  "チャネル別のCVRとROASを比較して",
  "初回購入月別の90日リテンションは?",
  "モバイルとPCで購買ファネルの離脱はどう違う?",
] as const;

function displayValue(value: unknown) {
  if (value === null || value === undefined) {
    return "NULL";
  }
  if (typeof value === "object") {
    return JSON.stringify(value);
  }
  return String(value);
}

function extractAnswer(content: AssistantBlock[]) {
  return content
    .filter((block): block is TextBlock => block.type === "text")
    .map((block) => block.text)
    .join("\n")
    .trim();
}

function toolResultPayload(result: QueryResult) {
  return JSON.stringify({
    rows: result.rows,
    returned_rows: result.returnedRows,
    displayed_rows: result.rows.length,
    truncated: result.truncated,
  });
}

export function AnalystChat() {
  const [question, setQuestion] = useState("");
  const [submittedQuestion, setSubmittedQuestion] = useState("");
  const [result, setResult] = useState<AnalystResult | null>(null);
  const [error, setError] = useState("");
  const [status, setStatus] = useState("");
  const [loading, setLoading] = useState(false);

  async function ask(nextQuestion: string) {
    const normalized = nextQuestion.trim();
    if (!normalized || loading) {
      return;
    }

    setQuestion(normalized);
    setSubmittedQuestion(normalized);
    setResult(null);
    setError("");
    setStatus("SQLを生成しています。");
    setLoading(true);

    const messages: AgentMessage[] = [
      { role: "user", content: normalized },
    ];
    let latestSql: string | null = null;
    let latestQueryResult: QueryResult = {
      rows: [],
      returnedRows: 0,
      truncated: false,
    };

    try {
      for (let round = 0; round < MAX_TOOL_ROUNDS; round += 1) {
        const response = await fetch("/api/analyst", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ messages }),
        });
        const payload = (await response.json()) as ProxyResponse;
        if (!response.ok) {
          throw new Error(
            payload.error ||
              "分析処理を完了できませんでした。時間を置いて再度お試しください。",
          );
        }
        if (!payload.assistantContent) {
          throw new Error("AIの応答形式を確認できませんでした。");
        }

        messages.push({
          role: "assistant",
          content: payload.assistantContent,
        });

        const toolUses = payload.toolUses ?? [];
        if (toolUses.length === 0) {
          if (payload.stopReason !== "end_turn") {
            throw new Error(
              "AIの応答が完了前に終了しました。質問を短くして再度お試しください。",
            );
          }
          const answer = extractAnswer(payload.assistantContent);
          setResult({
            answer:
              answer ||
              "回答を生成できませんでした。条件を変えて再度お試しください。",
            sql: latestSql,
            ...latestQueryResult,
          });
          return;
        }

        const toolResults: ToolResultBlock[] = [];
        for (const toolUse of toolUses) {
          latestSql = toolUse.sql || latestSql;
          if (!toolUse.valid) {
            toolResults.push({
              type: "tool_result",
              tool_use_id: toolUse.toolUseId,
              is_error: true,
              content: `SQLの安全性検証に失敗しました: ${toolUse.reason ?? "許可されていないSQLです。"} SQLを修正してください。`,
            });
            continue;
          }

          setStatus(
            round === 0
              ? "ブラウザに分析用Parquetを読み込み、SQLを実行しています。"
              : "修正されたSQLをブラウザ内で実行しています。",
          );
          try {
            latestQueryResult = await runBrowserQuery(toolUse.sql);
            toolResults.push({
              type: "tool_result",
              tool_use_id: toolUse.toolUseId,
              content: toolResultPayload(latestQueryResult),
            });
          } catch (queryError) {
            toolResults.push({
              type: "tool_result",
              tool_use_id: toolUse.toolUseId,
              is_error: true,
              content: `ブラウザ内でSQLを実行できませんでした: ${
                queryError instanceof Error
                  ? queryError.message
                  : "不明な実行エラーです。"
              } SQLを修正してください。`,
            });
          }
        }

        messages.push({ role: "user", content: toolResults });
        setStatus("実行結果を要約しています。");
      }

      throw new Error(
        "SQLの生成・修正回数が上限に達しました。条件を簡潔にして再度お試しください。",
      );
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "通信エラーが発生しました。",
      );
    } finally {
      setLoading(false);
      setStatus("");
    }
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    void ask(question);
  }

  const columns = result?.rows[0] ? Object.keys(result.rows[0]) : [];

  return (
    <div className="grid gap-6">
      <section className="rounded-card border border-border bg-surface p-5 md:p-6">
        <h2 className="text-sm font-semibold">質問</h2>
        <div className="mt-4 flex flex-wrap gap-2" aria-label="サンプル質問">
          {sampleQuestions.map((sample) => (
            <button
              key={sample}
              type="button"
              onClick={() => void ask(sample)}
              disabled={loading}
              className="rounded-full border border-border-strong bg-canvas px-3 py-2 text-left text-xs leading-5 text-ink-muted transition-colors hover:bg-canvas-subtle disabled:cursor-not-allowed disabled:opacity-50"
            >
              {sample}
            </button>
          ))}
        </div>

        <form onSubmit={handleSubmit} className="mt-5">
          <label htmlFor="analyst-question" className="sr-only">
            分析したい内容
          </label>
          <textarea
            id="analyst-question"
            value={question}
            onChange={(event) => setQuestion(event.target.value)}
            maxLength={2_000}
            rows={4}
            placeholder="例: 2025年のsource別に認識売上と注文数を比較して"
            className="w-full resize-y rounded-[10px] border border-border-strong bg-surface-strong px-4 py-3 text-sm leading-7 text-ink placeholder:text-ink-faint"
          />
          <div className="mt-3 flex items-center justify-between gap-4">
            <span className="font-mono text-[10px] text-ink-faint">
              {question.length.toLocaleString("ja-JP")} / 2,000
            </span>
            <button
              type="submit"
              disabled={loading || !question.trim()}
              className="inline-flex min-h-11 items-center justify-center rounded-[10px] bg-terracotta px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-terracotta-hover disabled:cursor-not-allowed disabled:opacity-50"
            >
              {loading ? "分析中…" : "分析する"}
            </button>
          </div>
        </form>
        <p className="mt-4 text-xs leading-6 text-ink-faint">
          公開用Parquetはこのブラウザ内でのみ読み込まれ、DuckDB-WASMでSQLを実行します。データは合成データです。
        </p>
      </section>

      <div aria-live="polite" aria-busy={loading}>
        {loading ? (
          <div className="rounded-card border border-border bg-canvas-subtle p-6">
            <p className="font-mono text-xs text-terracotta">ANALYZING</p>
            <p className="mt-3 text-sm leading-7 text-ink-muted">{status}</p>
          </div>
        ) : null}

        {error ? (
          <div
            role="alert"
            className="rounded-card border border-danger bg-surface p-6"
          >
            <p className="text-sm font-semibold text-danger">
              分析できませんでした
            </p>
            <p className="mt-2 text-sm leading-7 text-ink-muted">{error}</p>
          </div>
        ) : null}

        {result?.answer ? (
          <article className="overflow-hidden rounded-frame border border-border bg-surface">
            <header className="border-b border-border p-5 md:p-6">
              <p className="font-mono text-[10px] uppercase tracking-[0.12em] text-terracotta">
                Question
              </p>
              <p className="mt-2 text-sm leading-7">{submittedQuestion}</p>
            </header>

            <section className="p-5 md:p-6" aria-labelledby="answer-title">
              <h2 id="answer-title" className="font-display text-xl font-semibold">
                回答
              </h2>
              <p className="mt-4 whitespace-pre-wrap text-sm leading-8 text-ink-muted">
                {result.answer}
              </p>
            </section>

            {result.sql ? (
              <details className="border-t border-border">
                <summary className="cursor-pointer px-5 py-4 text-sm font-semibold md:px-6">
                  生成されたSQLを表示
                </summary>
                <pre className="overflow-x-auto border-t border-dark-border bg-dark-canvas p-5 font-mono text-xs leading-6 text-dark-text md:p-6">
                  <code>{result.sql}</code>
                </pre>
              </details>
            ) : null}

            {result.rows.length > 0 ? (
              <section
                className="border-t border-border"
                aria-labelledby="result-table-title"
              >
                <div className="flex flex-wrap items-center justify-between gap-3 px-5 py-4 md:px-6">
                  <h2 id="result-table-title" className="text-sm font-semibold">
                    クエリ結果
                  </h2>
                  <p className="font-mono text-[10px] text-ink-faint">
                    {result.returnedRows} rows
                    {result.truncated ? " / first 50 shown" : ""}
                  </p>
                </div>
                <div className="overflow-x-auto border-t border-border">
                  <table className="w-full min-w-[640px] border-collapse text-left text-xs">
                    <thead className="bg-canvas-subtle">
                      <tr>
                        {columns.map((column) => (
                          <th key={column} className="p-3 font-mono font-semibold">
                            {column}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {result.rows.map((row: QueryRow, rowIndex) => (
                        <tr key={rowIndex} className="border-t border-border">
                          {columns.map((column) => (
                            <td
                              key={column}
                              className="max-w-[320px] p-3 font-mono text-[11px] leading-5 text-ink-muted"
                            >
                              {displayValue(row[column])}
                            </td>
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </section>
            ) : null}
          </article>
        ) : null}
      </div>
    </div>
  );
}
