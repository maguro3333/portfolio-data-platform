import type { Metadata } from "next";
import { DashboardSelector } from "@/components/dashboards/dashboard-selector";
import { PageHero } from "@/components/sections/page-hero";
import { Section, SectionHeading } from "@/components/layout/section";
import { dashboardItems, martDefinitions } from "@/lib/site-data";

export const metadata: Metadata = {
  title: "Dashboards",
  description:
    "6つのECダッシュボードと、参照するdbt mart・主要指標の対応。",
};

export default function DashboardsPage() {
  return (
    <>
      <PageHero
        eyebrow="Dashboards"
        title="ダッシュボードと参照mart"
        copy="全体KPI、デジタルマーケティング、コンテンツ、RFM、コホート、購買ファネルの6画面を想定しています。プルダウンで対象を切り替えると、利用するmartと主要指標を確認できます。"
        meta={["Looker Studio", "Tableau Public", "Embed URLs pending"]}
      />

      <Section>
        <SectionHeading
          eyebrow="Dashboard viewer"
          title="ダッシュボードを選択"
          copy="公開URLは未確定のため埋め込み領域はplaceholderです。martと指標の対応は実装済みのdbt modelsに基づきます。"
        />
        <DashboardSelector dashboards={dashboardItems} />
      </Section>

      <Section className="border-y border-border bg-canvas-subtle">
        <SectionHeading
          eyebrow="Lineage reference"
          title="ダッシュボードからmartへ遡る"
          copy="各martのgrainと分析問いを一覧で確認できます。"
        />
        <div className="overflow-x-auto rounded-card border border-border bg-surface">
          <table className="w-full min-w-[900px] border-collapse text-left text-sm">
            <thead className="bg-surface-strong">
              <tr>
                <th className="p-4">Mart</th>
                <th className="p-4">粒度</th>
                <th className="p-4">答える問い</th>
                <th className="p-4">用途</th>
              </tr>
            </thead>
            <tbody>
              {martDefinitions
                .filter((mart) => mart.name !== "mart_customer_rfm_snapshot")
                .map((mart) => (
                  <tr key={mart.name} className="border-t border-border">
                    <td className="p-4 align-top font-mono text-xs font-semibold">{mart.name}</td>
                    <td className="p-4 align-top text-xs leading-6 text-ink-muted">{mart.grain}</td>
                    <td className="p-4 align-top leading-7">{mart.question}</td>
                    <td className="p-4 align-top text-xs leading-6 text-terracotta">{mart.consumers}</td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </Section>

      <Section>
        <SectionHeading eyebrow="Definitions" title="共通の表示条件" />
        <dl className="grid gap-4 md:grid-cols-2">
          {[
            ["認識売上", "completed注文のitem net sales。税・送料をAOVとROASに含めない。"],
            ["Attribution", "購入前30日。last non-directとlinearの2方式を保持。"],
            ["RFM公開", "顧客明細は公開せず、customers >= 10の集計segmentだけを使用。"],
            ["Cohort", "未成熟期間は0ではなくNULLとし、未来期間を比較対象にしない。"],
          ].map(([term, detail]) => (
            <div key={term} className="rounded-card border border-border bg-surface p-5">
              <dt className="font-mono text-xs font-semibold">{term}</dt>
              <dd className="mt-3 text-sm leading-7 text-ink-muted">{detail}</dd>
            </div>
          ))}
        </dl>
      </Section>
    </>
  );
}
