import type { Metadata } from "next";
import { AnalystChat } from "@/components/analyst/analyst-chat";
import { PageHero } from "@/components/sections/page-hero";
import { Section, SectionHeading } from "@/components/layout/section";
import { Badge } from "@/components/ui/badge";
import { ALLOWED_MARTS } from "@/lib/agent/sql-guard";

export const metadata: Metadata = {
  title: "AI Analyst",
  description:
    "公開EC分析martへ自然言語で問い合わせ、生成SQLと結果を確認できるtext-to-SQL機能。",
};

export default function AiAnalystPage() {
  return (
    <>
      <PageHero
        eyebrow="AI Analyst"
        title="公開martへの自然言語問い合わせ"
        copy="Claudeが生成したDuckDB SQLをサーバーで検証し、公開用Parquet martに対してブラウザ内で実行します。回答、生成SQL、結果の先頭行を同じ画面で確認できます。"
        meta={["Anthropic tool use", "Browser DuckDB-WASM", "SELECT / WITH only", "合成データ"]}
      />

      <Section>
        <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_280px]">
          <AnalystChat />
          <aside className="space-y-4 lg:sticky lg:top-24 lg:self-start">
            <div className="rounded-card border border-border bg-surface p-5">
              <Badge tone="sage">Read only</Badge>
              <h2 className="mt-4 text-sm font-semibold">実行制約</h2>
              <ul className="mt-3 space-y-2 text-xs leading-6 text-ink-muted">
                <li>SELECT / WITHのみ</li>
                <li>結果表示は先頭50行</li>
                <li>実行上限1,000行</li>
                <li>質問は2,000文字以内</li>
                <li>IP単位の簡易rate limit</li>
                <li>ParquetとSQL実行はブラウザ内</li>
              </ul>
            </div>
            <div className="rounded-card border border-border bg-canvas-subtle p-5">
              <h2 className="text-sm font-semibold">参照可能なmart</h2>
              <ul className="mt-3 space-y-2">
                {ALLOWED_MARTS.map((mart) => (
                  <li key={mart} className="font-mono text-[10px] leading-5 text-ink-muted">
                    {mart}
                  </li>
                ))}
              </ul>
            </div>
          </aside>
        </div>
      </Section>

      <Section className="border-y border-border bg-canvas-subtle">
        <SectionHeading eyebrow="Scope" title="利用上の注意" />
        <div className="grid gap-4 text-sm leading-7 text-ink-muted md:grid-cols-3">
          <p className="rounded-card border border-border bg-surface p-5">
            対象は2024〜2025年の合成ECデータです。実在する顧客、注文、企業の実績ではありません。
          </p>
          <p className="rounded-card border border-border bg-surface p-5">
            回答は生成SQLの実行結果に基づきますが、指標の選択や解釈が質問意図と合うか、表示SQLと結果を確認してください。
          </p>
          <p className="rounded-card border border-border bg-surface p-5">
            顧客粒度の内部RFM martは含めず、customers ≥ 10の公開用集計martだけを参照します。
          </p>
        </div>
      </Section>
    </>
  );
}
