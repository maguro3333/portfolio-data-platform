import type { Metadata } from "next";
import { PageHero } from "@/components/sections/page-hero";
import { Section, SectionHeading } from "@/components/layout/section";
import { Card } from "@/components/ui/card";

export const metadata: Metadata = {
  title: "About",
  description:
    "フリーランスデータエンジニア小田航平の職務要約、経験領域、利用技術。",
};

const skillGroups = [
  {
    category: "Data engineering",
    skills: "Python、SQL、BigQuery",
    experience: "データ加工、集計処理、DWH・データマートの設計と実装",
  },
  {
    category: "Measurement",
    skills: "GA4、Google Tag Manager",
    experience: "イベント・パラメータ・conversionの計測設計と検証",
  },
  {
    category: "Business intelligence",
    skills: "Looker Studio、Tableau",
    experience: "KPI定義、ダッシュボード設計、利用部門向けの可視化",
  },
  {
    category: "Current portfolio work",
    skills: "AWS、dbt Core、Terraform",
    experience: "S3・Glue・Athena構成とクロスエンジンdbtを本プロジェクトで実装",
  },
] as const;

export default function AboutPage() {
  return (
    <>
      <PageHero
        eyebrow="About"
        title="経歴・対応領域"
        copy="小田航平。フリーランスのデータエンジニアです。Python・SQLを6年使用し、BigQuery、GA4/GTM計測設計、Looker Studio、Tableauを用いたデータ基盤・分析・可視化業務を経験しています。"
        meta={["職務経歴書PDFは非公開", "AWSは本サンプルでの構築経験として記載"]}
        aside={
          <dl className="rounded-card border border-border bg-canvas p-5 text-sm">
            <div className="grid grid-cols-[90px_1fr] gap-3">
              <dt className="text-ink-faint">氏名</dt>
              <dd>小田 航平</dd>
            </div>
            <div className="mt-3 grid grid-cols-[90px_1fr] gap-3">
              <dt className="text-ink-faint">職種</dt>
              <dd>Data Engineer</dd>
            </div>
            <div className="mt-3 grid grid-cols-[90px_1fr] gap-3">
              <dt className="text-ink-faint">形態</dt>
              <dd>Freelance</dd>
            </div>
          </dl>
        }
      />

      <Section>
        <div className="grid gap-10 lg:grid-cols-12">
          <div className="lg:col-span-4">
            <SectionHeading eyebrow="Summary" title="職務要約" />
          </div>
          <div className="space-y-5 text-base leading-8 text-ink-muted lg:col-span-8">
            <p>
              Python・SQLを中心に、データ収集後の加工、BigQuery上の分析用データ整備、BIダッシュボード作成を担当してきました。
            </p>
            <p>
              Web行動データについては、GA4/GTMのイベント計測設計から、購買・会員データと結合して分析するためのデータ定義までを扱います。
            </p>
            <p>
              業務では、事業部門の確認事項をKPI、データ粒度、必要な計測項目へ整理し、実装担当と利用部門の間で定義を共有する役割を含みます。
            </p>
          </div>
        </div>
      </Section>

      <Section className="border-y border-border bg-canvas-subtle">
        <SectionHeading
          eyebrow="Skills"
          title="活用できる技術と担当範囲"
          copy="経験年数のバー表示ではなく、各技術で担当した内容を記載します。"
        />
        <div className="overflow-x-auto rounded-card border border-border bg-surface">
          <table className="w-full min-w-[760px] border-collapse text-left text-sm">
            <thead className="bg-surface-strong">
              <tr>
                <th className="p-4 font-semibold">領域</th>
                <th className="p-4 font-semibold">技術</th>
                <th className="p-4 font-semibold">担当内容</th>
              </tr>
            </thead>
            <tbody>
              {skillGroups.map((group) => (
                <tr key={group.category} className="border-t border-border">
                  <td className="p-4 font-mono text-xs">{group.category}</td>
                  <td className="p-4 font-medium">{group.skills}</td>
                  <td className="p-4 leading-7 text-ink-muted">{group.experience}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Section>

      <Section>
        <SectionHeading
          eyebrow="Career"
          title="略歴"
          copy="所属、期間、主な担当を職務経歴書の公開可能な範囲で要約しています。"
        />
        <ol className="overflow-hidden rounded-card border border-border bg-surface">
          {[
            {
              period: "2016.04–2019.10",
              company: "株式会社イー・ガーディアン",
              role: "広告レポーティング、10名規模チームの品質・進捗管理",
            },
            {
              period: "2019.12–2022.01",
              company: "株式会社ベイクルーズ",
              role: "EC運用、BigQueryを中心としたデータ活用基盤、Python業務自動化、BI",
            },
            {
              period: "2022.02–2025.02",
              company: "株式会社デイトナ・インターナショナル",
              role: "GA4主管、データマート・連携処理、BI、KPI設計、MA施策、データ活用支援",
            },
            {
              period: "2025.07–2026.06",
              company: "株式会社リクルートスタッフィングを通じ、株式会社みずほフィナンシャルグループ",
              role: "金融犯罪対策部門のデータエンジニア。要件定義、設計、実装、テスト、リリース手順整備",
            },
          ].map((entry) => (
            <li
              key={entry.period}
              className="grid gap-2 border-b border-border p-5 last:border-b-0 md:grid-cols-[150px_280px_1fr]"
            >
              <time className="font-mono text-xs text-terracotta">{entry.period}</time>
              <h2 className="text-sm font-semibold">{entry.company}</h2>
              <p className="text-sm leading-7 text-ink-muted">{entry.role}</p>
            </li>
          ))}
        </ol>
      </Section>

      <Section className="border-y border-border bg-canvas-subtle">
        <SectionHeading eyebrow="Responsibilities" title="担当できる工程" />
        <ol className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[
            ["01", "要件・計測設計", "利用者、判断内容、KPI、イベント、パラメータを整理。"],
            ["02", "データモデル", "sourceの粒度と関係を確認し、CoreとMartを設計。"],
            ["03", "実装・品質", "Python/SQLで処理を実装し、参照整合・業務ルールを検証。"],
            ["04", "BI・利用支援", "ダッシュボードを作成し、定義と利用方法を共有。"],
          ].map(([index, title, description]) => (
            <li key={index} className="border-t-2 border-terracotta pt-4">
              <span className="font-mono text-xs text-terracotta">{index}</span>
              <h2 className="mt-3 font-display text-lg font-semibold">{title}</h2>
              <p className="mt-2 text-sm leading-7 text-ink-muted">{description}</p>
            </li>
          ))}
        </ol>
      </Section>

      <Section className="bg-surface">
        <SectionHeading eyebrow="Project context" title="本ポートフォリオで追加検証した領域" />
        <div className="grid gap-4 md:grid-cols-3">
          <Card>
            <h2 className="font-mono text-sm font-semibold">AWS lakehouse</h2>
            <p className="mt-3 text-sm leading-7 text-ink-muted">
              S3、Glue、Athena、Parquetを使ったserverless構成。AWS実務経験とは区別しています。
            </p>
          </Card>
          <Card>
            <h2 className="font-mono text-sm font-semibold">Cross-engine dbt</h2>
            <p className="mt-3 text-sm leading-7 text-ink-muted">
              DuckDB、BigQuery、Athenaで同じモデルとテストを実行し、KPIを照合。
            </p>
          </Card>
          <Card>
            <h2 className="font-mono text-sm font-semibold">Infrastructure as Code</h2>
            <p className="mt-3 text-sm leading-7 text-ink-muted">
              GCP/AWSのresource、権限、コストガードをTerraformで定義。
            </p>
          </Card>
        </div>
      </Section>
    </>
  );
}
