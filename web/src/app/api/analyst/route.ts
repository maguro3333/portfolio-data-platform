import Anthropic from "@anthropic-ai/sdk";
import { SYSTEM_PROMPT } from "@/lib/agent/prompt";
import { checkRateLimit, getClientIp } from "@/lib/agent/rate-limit";
import { validateReadOnlySql } from "@/lib/agent/sql-guard";

export const runtime = "nodejs";
export const maxDuration = 30;

const MODEL = process.env.AGENT_MODEL || "claude-sonnet-5";
const MAX_QUESTION_LENGTH = 2_000;
const MAX_MESSAGES = 12;
const MAX_REQUEST_BYTES = 160_000;

const runSqlTool = {
  name: "run_sql",
  description:
    "公開済みEC分析martに対するread-onlyのDuckDB SQLを提示します。SQLの実行はブラウザ側で行われます。",
  input_schema: {
    type: "object" as const,
    properties: {
      sql: {
        type: "string",
        description: "SELECTまたはWITHで始まるDuckDB SQL",
      },
    },
    required: ["sql"],
    additionalProperties: false,
  },
};

type AnalystRequest = {
  messages?: unknown;
};

type ToolValidation = {
  toolUseId: string;
  sql: string;
  valid: boolean;
  reason: string | null;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function validateMessages(
  input: unknown,
): Anthropic.Messages.MessageParam[] | null {
  if (!Array.isArray(input) || input.length === 0 || input.length > MAX_MESSAGES) {
    return null;
  }
  if (
    !input.every(
      (message) =>
        isRecord(message) &&
        (message.role === "user" || message.role === "assistant") &&
        (typeof message.content === "string" ||
          (Array.isArray(message.content) &&
            message.content.length > 0 &&
            message.content.length <= 10)),
    )
  ) {
    return null;
  }
  return input as Anthropic.Messages.MessageParam[];
}

function initialQuestion(messages: Anthropic.Messages.MessageParam[]) {
  const first = messages[0];
  return first?.role === "user" && typeof first.content === "string"
    ? first.content.trim()
    : "";
}

function validateToolUse(
  block: Anthropic.Messages.ToolUseBlock,
): ToolValidation {
  const input = block.input as { sql?: unknown };
  if (typeof input.sql !== "string") {
    return {
      toolUseId: block.id,
      sql: "",
      valid: false,
      reason: "run_sqlにはsql文字列が必要です。",
    };
  }

  try {
    return {
      toolUseId: block.id,
      sql: validateReadOnlySql(input.sql),
      valid: true,
      reason: null,
    };
  } catch (error) {
    return {
      toolUseId: block.id,
      sql: input.sql,
      valid: false,
      reason:
        error instanceof Error ? error.message : "SQLを検証できませんでした。",
    };
  }
}

export async function POST(request: Request) {
  const contentLength = Number(request.headers.get("content-length") || "0");
  if (
    Number.isFinite(contentLength) &&
    contentLength > MAX_REQUEST_BYTES
  ) {
    return Response.json(
      {
        error: "会話履歴が大きすぎます。質問を短くして再度お試しください。",
        code: "REQUEST_TOO_LARGE",
      },
      { status: 413 },
    );
  }

  const rate = checkRateLimit(getClientIp(request));
  if (!rate.allowed) {
    return Response.json(
      {
        error: `短時間の利用上限に達しました。${rate.retryAfterSeconds}秒ほど待ってから再度お試しください。`,
        code: "RATE_LIMITED",
      },
      {
        status: 429,
        headers: { "Retry-After": String(rate.retryAfterSeconds) },
      },
    );
  }

  if (!process.env.ANTHROPIC_API_KEY) {
    return Response.json(
      {
        error:
          "AI Analystは現在準備中です。サーバー側のANTHROPIC_API_KEY設定後に利用できます。",
        code: "NOT_CONFIGURED",
      },
      { status: 503 },
    );
  }

  let body: AnalystRequest;
  try {
    const requestText = await request.text();
    if (new TextEncoder().encode(requestText).byteLength > MAX_REQUEST_BYTES) {
      return Response.json(
        {
          error: "会話履歴が大きすぎます。質問を短くして再度お試しください。",
          code: "REQUEST_TOO_LARGE",
        },
        { status: 413 },
      );
    }
    body = JSON.parse(requestText) as AnalystRequest;
  } catch {
    return Response.json(
      { error: "リクエストの形式を確認してください。", code: "INVALID_JSON" },
      { status: 400 },
    );
  }

  const messages = validateMessages(body.messages);
  if (!messages) {
    return Response.json(
      { error: "会話履歴の形式を確認してください。", code: "INVALID_MESSAGES" },
      { status: 400 },
    );
  }

  const question = initialQuestion(messages);
  if (!question) {
    return Response.json(
      { error: "質問を入力してください。", code: "EMPTY_QUESTION" },
      { status: 400 },
    );
  }
  if (question.length > MAX_QUESTION_LENGTH) {
    return Response.json(
      {
        error: `質問は${MAX_QUESTION_LENGTH.toLocaleString("ja-JP")}文字以内で入力してください。`,
        code: "QUESTION_TOO_LONG",
      },
      { status: 400 },
    );
  }

  try {
    const anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
    const response = await anthropic.messages.create({
      model: MODEL,
      max_tokens: 1_500,
      system: [
        {
          type: "text",
          text: SYSTEM_PROMPT,
          cache_control: { type: "ephemeral" },
        },
      ],
      tools: [runSqlTool],
      messages,
    });
    const toolUses = response.content
      .filter(
        (block): block is Anthropic.Messages.ToolUseBlock =>
          block.type === "tool_use",
      )
      .map(validateToolUse);

    return Response.json({
      assistantContent: response.content,
      stopReason: response.stop_reason,
      toolUses,
      model: MODEL,
    });
  } catch (error) {
    console.error("AI Analyst proxy request failed", error);
    return Response.json(
      {
        error:
          "分析応答を生成できませんでした。しばらく待ってから再度お試しください。",
        code: "ANALYST_ERROR",
      },
      { status: 502 },
    );
  }
}
