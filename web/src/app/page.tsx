import Link from "next/link";
import { Section, SectionHeading } from "@/components/layout/section";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { projectFacts } from "@/lib/site-data";

const pages = [
  {
    href: "/about",
    index: "01",
    title: "About",
    description:
      "小田航平の職務要約、経験領域、利用技術、担当可能な工程を確認できます。",
    contents: "Python / SQL 6年、BigQuery、GA4・GTM、BI",
  },
  {
    href: "/architecture",
    index: "02",
    title: "Architecture",
    description:
      "GCP版・AWS版・Webサイトの構成、実装順序、各技術を採用した理由を確認できます。",
    contents: "BigQuery warehouse / S3 + Athena lakehouse / Terraform",
  },
  {
    href: "/data-pipeline",
    index: "03",
    title: "Data & Pipeline",
    description:
      "合成データのテーブル定義、rawからmartまでの加工意図、品質テストを確認できます。",
    contents: "10 core tables / 26 dbt models / 8 marts / 141 tests",
  },
  {
    href: "/dashboards",
    index: "04",
    title: "Dashboards",
    description:
      "6つのダッシュボード案と、それぞれが参照するmart・主要指標を確認できます。",
    contents: "KPI / Marketing / Content / RFM / Cohort / Funnel",
  },
  {
    href: "/ai-analyst",
    index: "05",
    title: "AI Analyst",
    description:
      "公開martへ自然言語で問い合わせ、生成SQL、実行結果、日本語の要約を確認できます。",
    contents: "Anthropic tool use / DuckDB-WASM / 7 public marts",
  },
] as const;

export default function Home() {
  return (
    <>
      <header className="border-b border-border bg-surface px-5 py-10 md:px-8 md:py-12">
        <div className="mx-auto max-w-[1200px]">
          <p className="font-mono text-[11px] font-semibold uppercase tracking-[0.16em] text-terracotta">
            Portfolio index
          </p>
          <h1 className="mt-3 font-display text-3xl font-semibold tracking-[-0.025em] md:text-4xl">
            小田航平 — データエンジニア
          </h1>
          <p className="mt-4 max-w-[50rem] text-base leading-8 text-ink-muted">
            フリーランス案件向けのポートフォリオです。EC購買データとGA4 BigQuery Exportを参考にした行動ログを生成し、GCPとAWSに同じ論理モデルを実装したサンプルプロジェクトについて、構成・データ定義・変換・品質・BIの順に記載しています。
          </p>
        </div>
      </header>

      <Section>
        <SectionHeading
          eyebrow="Contents"
          title="このサイトで確認できる内容"
          copy="各ページは、経歴、システム構成、データ実装、BI利用の順で読めるように分けています。"
        />
        <nav className="grid gap-4 md:grid-cols-2" aria-label="ポートフォリオの目次">
          {pages.map((page) => (
            <Link
              key={page.href}
              href={page.href}
              className="group rounded-card border border-border bg-surface p-5 transition-colors hover:border-border-strong hover:bg-surface-strong md:p-6"
            >
              <div className="flex items-start justify-between gap-4">
                <span className="font-mono text-xs text-terracotta">{page.index}</span>
                <span
                  className="text-ink-faint transition-transform group-hover:translate-x-1"
                  aria-hidden="true"
                >
                  →
                </span>
              </div>
              <h2 className="mt-4 font-display text-xl font-semibold">{page.title}</h2>
              <p className="mt-3 text-sm leading-7 text-ink-muted">{page.description}</p>
              <p className="mt-5 border-t border-border pt-4 font-mono text-[10px] leading-5 uppercase tracking-[0.08em] text-ink-faint">
                {page.contents}
              </p>
            </Link>
          ))}
        </nav>
      </Section>

      <Section className="border-y border-border bg-canvas-subtle">
        <div className="grid gap-10 lg:grid-cols-12">
          <div className="lg:col-span-4">
            <SectionHeading
              eyebrow="Project at a glance"
              title="ECデータ基盤サンプル"
              copy="2024〜2025年の合成データを使い、クラウドごとの物理構成と共通の分析ロジックを検証しています。"
            />
            <Badge tone="sage">No personal data</Badge>
          </div>
          <dl className="overflow-hidden rounded-card border border-border bg-surface lg:col-span-8">
            {projectFacts.map((fact) => (
              <div
                key={fact.term}
                className="grid gap-2 border-b border-border px-5 py-4 last:border-b-0 md:grid-cols-[150px_1fr]"
              >
                <dt className="font-mono text-[11px] font-semibold uppercase tracking-[0.1em] text-terracotta">
                  {fact.term}
                </dt>
                <dd className="text-sm leading-6 text-ink-muted">{fact.detail}</dd>
              </div>
            ))}
          </dl>
        </div>
      </Section>

      <Section>
        <SectionHeading eyebrow="Implementation scope" title="このサンプルで実装した範囲" />
        <div className="grid gap-4 md:grid-cols-3">
          <Card>
            <h2 className="font-display text-lg font-semibold">データ生成・契約</h2>
            <p className="mt-3 text-sm leading-7 text-ink-muted">
              seedで再現可能なPython生成処理、YAMLの論理schema contract、品質レポート。
            </p>
          </Card>
          <Card>
            <h2 className="font-display text-lg font-semibold">クラウド・変換</h2>
            <p className="mt-3 text-sm leading-7 text-ink-muted">
              BigQueryとAthenaのDDL、Terraform、共通dbt project、方言吸収macro。
            </p>
          </Card>
          <Card>
            <h2 className="font-display text-lg font-semibold">分析・公開</h2>
            <p className="mt-3 text-sm leading-7 text-ink-muted">
              KPI・Marketing・Content・RFM・Cohort・FunnelのmartとBI設計、本Webサイト。
            </p>
          </Card>
        </div>
      </Section>
    </>
  );
}
