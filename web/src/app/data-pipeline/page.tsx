import type { Metadata } from "next";
import { PageHero } from "@/components/sections/page-hero";
import { Section, SectionHeading } from "@/components/layout/section";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { coreTables, dataScale, martDefinitions } from "@/lib/site-data";

export const metadata: Metadata = {
  title: "Data & Pipeline",
  description:
    "EC購買・GA4準拠行動ログのテーブル定義、rawからmartまでの加工意図、品質テスト。",
};

const layers = [
  {
    layer: "Raw",
    input: "generator output",
    processing: "gzip CSVをテーブル別に保存。入力時点では全列を文字列として扱う。",
    output: "クラウドごとのraw source",
  },
  {
    layer: "Staging",
    input: "raw tables",
    processing: "型変換、NULL正規化、文字列のcase統一、timestamp・money・booleanの方言吸収。",
    output: "stg_dim_* / stg_fact_*",
  },
  {
    layer: "Intermediate / Core",
    input: "staging models",
    processing: "セッションの顧客区分、イベント順序ファネル、注文前touchpoint、注文明細集計を導出。",
    output: "int_sessions_enriched / int_session_funnel / int_order_touchpoints 等",
  },
  {
    layer: "Marts",
    input: "staging + intermediate",
    processing: "利用部門と分析問いごとの粒度へ集約。公開用martでは顧客明細を出さない。",
    output: "8 BI / analysis marts",
  },
] as const;

export default function DataPipelinePage() {
  return (
    <>
      <PageHero
        eyebrow="Data & Pipeline"
        title="データ定義・変換レイヤー・分析用mart"
        copy="Python generatorが出力するEC購買・行動ログを、共通schema contractに従って型付けし、セッション・ファネル・アトリビューションを導出した後、BI用途別のmartへ変換します。"
        meta={["2024–2025", "10 core/bridge groups", "26 dbt models", "8 marts", "141 tests"]}
      />

      <Section>
        <div className="grid gap-10 lg:grid-cols-12">
          <div className="lg:col-span-5">
            <SectionHeading
              eyebrow="Sample data"
              title="合成データの構成"
              copy="実在の個人・取引データは使用していません。季節性、campaign、cancel・全額refund、repeat、30日lookback attributionを生成条件に含めています。"
            />
            <dl className="space-y-3 text-sm">
              <div className="grid grid-cols-[120px_1fr] gap-3">
                <dt className="text-ink-faint">認識売上</dt>
                <dd className="metric-numerals font-semibold">¥124,544,333</dd>
              </div>
              <div className="grid grid-cols-[120px_1fr] gap-3">
                <dt className="text-ink-faint">Session CVR</dt>
                <dd className="metric-numerals font-semibold">4.63%</dd>
              </div>
              <div className="grid grid-cols-[120px_1fr] gap-3">
                <dt className="text-ink-faint">Funnel</dt>
                <dd className="metric-numerals font-semibold">100,100 → 27,940 → 16,940 → 10,500</dd>
              </div>
            </dl>
          </div>
          <dl className="grid grid-cols-2 gap-3 lg:col-span-7">
            {dataScale.map((item) => (
              <div key={item.label} className="rounded-card border border-border bg-surface p-5">
                <dd className="metric-numerals font-display text-2xl font-semibold">{item.value}</dd>
                <dt className="mt-2 font-mono text-[10px] uppercase tracking-[0.12em] text-ink-muted">
                  {item.label}
                </dt>
              </div>
            ))}
          </dl>
        </div>
      </Section>

      <Section className="border-y border-border bg-canvas-subtle">
        <SectionHeading
          eyebrow="Logical types"
          title="BigQueryとAthenaで共有する型の意味"
          copy="論理型はschema_contract.yamlで管理し、物理型だけをadapter別に割り当てます。"
        />
        <div className="overflow-x-auto rounded-card border border-border bg-surface">
          <table className="w-full min-w-[700px] border-collapse text-left text-sm">
            <thead className="bg-surface-strong">
              <tr>
                <th className="p-4">Logical</th>
                <th className="p-4 text-sage">BigQuery</th>
                <th className="p-4 text-amber">Athena</th>
                <th className="p-4">用途</th>
              </tr>
            </thead>
            <tbody className="[&_tr]:border-t [&_tr]:border-border [&_td]:p-4">
              <tr><td>string</td><td>STRING</td><td>STRING</td><td>ID・属性</td></tr>
              <tr><td>integer</td><td>INT64</td><td>BIGINT</td><td>件数・sequence</td></tr>
              <tr><td>money</td><td>NUMERIC</td><td>DECIMAL(18,2)</td><td>売上・費用・原価</td></tr>
              <tr><td>rate</td><td>NUMERIC</td><td>DECIMAL(18,6)</td><td>attribution credit</td></tr>
              <tr><td>boolean</td><td>BOOL</td><td>BOOLEAN</td><td>状態flag</td></tr>
              <tr><td>date / timestamp</td><td>DATE / TIMESTAMP</td><td>DATE / TIMESTAMP</td><td>partition・時系列</td></tr>
            </tbody>
          </table>
        </div>
      </Section>

      <Section>
        <SectionHeading
          eyebrow="Core tables"
          title="主要テーブル定義"
          copy="全列一覧ではなく、grain、key、分析で使用する主要列を掲載しています。正式な契約はgenerator/schema_contract.yamlを基準とします。"
        />
        <div className="overflow-x-auto rounded-card border border-border bg-surface">
          <table className="w-full min-w-[1100px] border-collapse text-left text-[13px]">
            <thead className="bg-surface-strong">
              <tr>
                <th className="p-4">Table</th>
                <th className="p-4">種別</th>
                <th className="p-4">粒度</th>
                <th className="p-4">Key</th>
                <th className="p-4">主要カラム / 型</th>
                <th className="p-4">用途</th>
              </tr>
            </thead>
            <tbody>
              {coreTables.map((table) => (
                <tr key={table.name} className="border-t border-border">
                  <td className="p-4 align-top font-mono font-semibold">{table.name}</td>
                  <td className="p-4 align-top">{table.kind}</td>
                  <td className="p-4 align-top leading-6">{table.grain}</td>
                  <td className="p-4 align-top font-mono text-xs leading-6">{table.keys}</td>
                  <td className="max-w-[340px] p-4 align-top font-mono text-[11px] leading-6 text-ink-muted">
                    {table.columns}
                  </td>
                  <td className="p-4 align-top leading-6 text-ink-muted">{table.purpose}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Section>

      <Section className="border-y border-border bg-surface">
        <SectionHeading
          eyebrow="Transformation"
          title="rawからmartまでの加工意図"
        />
        <ol className="grid gap-4 lg:grid-cols-4">
          {layers.map((layer, index) => (
            <li key={layer.layer} className="rounded-card border border-border bg-canvas p-5">
              <p className="font-mono text-[10px] text-terracotta">0{index + 1}</p>
              <h2 className="mt-3 font-display text-lg font-semibold">{layer.layer}</h2>
              <dl className="mt-5 space-y-4 text-sm">
                <div>
                  <dt className="text-xs text-ink-faint">Input</dt>
                  <dd className="mt-1 font-mono text-xs">{layer.input}</dd>
                </div>
                <div>
                  <dt className="text-xs text-ink-faint">Processing</dt>
                  <dd className="mt-1 leading-7 text-ink-muted">{layer.processing}</dd>
                </div>
                <div>
                  <dt className="text-xs text-ink-faint">Output</dt>
                  <dd className="mt-1 font-mono text-xs leading-6">{layer.output}</dd>
                </div>
              </dl>
            </li>
          ))}
        </ol>
      </Section>

      <Section>
        <SectionHeading
          eyebrow="Marts"
          title="分析用martの問いと粒度"
          copy="ダッシュボード側で複雑な結合やbusiness ruleを再実装しないよう、用途ごとの粒度へ変換します。"
        />
        <div className="space-y-3">
          {martDefinitions.map((mart) => (
            <Card
              key={mart.name}
              className="grid gap-4 md:grid-cols-[230px_260px_1fr_180px] md:items-start"
            >
              <h2 className="font-mono text-sm font-semibold">{mart.name}</h2>
              <p className="text-xs leading-6 text-ink-muted">{mart.grain}</p>
              <p className="text-sm leading-7">{mart.question}</p>
              <p className="text-xs leading-6 text-terracotta">{mart.consumers}</p>
            </Card>
          ))}
        </div>
      </Section>

      <Section className="bg-dark-canvas text-dark-text">
        <div className="grid gap-8 lg:grid-cols-12">
          <div className="lg:col-span-4">
            <Badge tone="dark">Validation</Badge>
            <h2 className="mt-4 font-display text-2xl font-semibold">品質テストとエンジン照合</h2>
          </div>
          <div className="grid gap-4 text-sm leading-7 text-dark-muted md:grid-cols-2 lg:col-span-8">
            <p>
              unique、not_null、relationships、accepted_valuesに加え、金額式、order header-item、purchase-order、funnel単調性、attribution credit合計、RFM未来情報、cohort成熟度をsingular testで検証します。
            </p>
            <p>
              DuckDB、BigQuery、Athenaの各targetでdbt build 141テストが全通過し、日次orders・recognized revenue等のreconciliation結果が一致しています。
            </p>
          </div>
        </div>
      </Section>
    </>
  );
}
