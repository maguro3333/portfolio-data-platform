import type { Metadata } from "next";
import { ArchitectureFrame, FlowNode } from "@/components/diagrams/architecture-frame";
import { PageHero } from "@/components/sections/page-hero";
import { Section, SectionHeading } from "@/components/layout/section";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";

export const metadata: Metadata = {
  title: "Architecture",
  description:
    "ECデータ基盤サンプルのGCP版・AWS版・Webサイト構成、実装ワークフロー、技術選定理由。",
};

const workflow = [
  ["01", "Generate", "Python generator", "schema contractに従い、2年分のEC購買・行動ログを再現可能なseedで生成。"],
  ["02", "Load", "GCS / S3", "同じ論理データを各クラウドへ配置。AWS側はParquetへ変換。"],
  ["03", "Transform", "dbt Core", "staging、intermediate、martsの26モデルをadapter別targetで実行。"],
  ["04", "Validate", "dbt tests", "schema・relationship・business rule・reconciliationの141テストを実行。"],
  ["05", "Visualize", "Looker / Tableau", "利用部門別のmartを接続し、6つのダッシュボードを作成。"],
  ["06", "Publish", "Next.js / Vercel", "構成、データ定義、検証結果、BIを本サイトで説明。"],
] as const;

const technologies = [
  {
    name: "BigQuery",
    role: "GCP側のwarehouse",
    reason: "管理負荷が低く、partition/clusterを使った列指向DWHとして既存の実務経験を示すため。",
    implementation: "GCSからCoreをロードし、dbt-bigqueryでstagingからmartsまで変換。",
  },
  {
    name: "S3 + Glue + Athena",
    role: "AWS側のserverless lakehouse",
    reason: "storage/compute分離、Parquet、catalog、scan-based costを含むlakehouse構成を実装するため。",
    implementation: "S3にParquetを配置し、Glue Catalog経由でAthenaからdbt-athenaを実行。",
  },
  {
    name: "dbt Core",
    role: "共通の変換・品質レイヤー",
    reason: "クラウドが変わってもKPI定義とデータ品質条件を同じprojectで管理するため。",
    implementation: "論理モデルは共通。money、timestamp、date等の方言差をadapter macroへ隔離。",
  },
  {
    name: "Terraform",
    role: "両クラウドのIaC",
    reason: "resource、権限、削除可能性、コストガードをコードでレビューできるようにするため。",
    implementation: "GCP/AWSを別moduleに分け、環境固有値と再利用するresource定義を分離。",
  },
  {
    name: "DuckDB",
    role: "ローカルの分析ロジック検証",
    reason: "クラウド投入前に認証・課金なしでdbtモデルとテストを反復するため。",
    implementation: "generatorのgzip CSVを読み、同じdbt projectのduckdb targetを実行。",
  },
  {
    name: "Next.js + Vercel",
    role: "本解説サイト",
    reason: "構成・テーブル・mart・BIの関係を静的中心のWebサイトとして公開するため。",
    implementation: "App Router、typed TSX、Tailwind v4。Contact以外をindex対象にする。",
  },
] as const;

export default function ArchitecturePage() {
  return (
    <>
      <PageHero
        eyebrow="Architecture"
        title="システム構成と実装ワークフロー"
        copy="同一のEC論理モデルをBigQuery warehouseとS3/Athena lakehouseへ実装し、dbtのモデル・KPI・品質テストを共通化したサンプルプロジェクトです。このページでは、構成、処理順序、技術ごとの用途を記載します。"
        meta={["GCP + AWS", "Terraform", "dbt Core", "Next.js on Vercel"]}
      />

      <Section>
        <div className="grid gap-10 lg:grid-cols-12">
          <div className="lg:col-span-4">
            <SectionHeading eyebrow="Purpose" title="実装意図" />
          </div>
          <div className="space-y-5 text-sm leading-7 text-ink-muted lg:col-span-8">
            <p>
              GCP実務で扱ってきたBigQuery構成に加え、AWSでS3・Glue・Athenaを使う場合の設計と運用差を、同一データで比較できる形にしました。
            </p>
            <p>
              クラウドサービスを同じ形へ無理に揃えるのではなく、論理列、粒度、KPI、品質条件を共通化し、partition、cluster、Parquetなどの物理最適化を各クラウドへ分けています。
            </p>
            <p>
              無料枠を前提に、BigQueryは約0.55GB、S3上のParquetは約34MBに収め、Athena Workgroupのscan上限をコストガードとして使用する方針です。
            </p>
          </div>
        </div>
      </Section>

      <Section className="border-y border-border bg-canvas-subtle">
        <SectionHeading
          eyebrow="System diagrams"
          title="GCP版・AWS版・Webサイト"
          copy="矢印はデータまたは成果物の主な流れを示します。"
        />
        <div className="grid gap-5">
          <ArchitectureFrame
            title="GCP implementation"
            caption="BigQueryをmanaged warehouseとして使用。dbt-bigqueryがCoreからBI向けmartを作成します。"
          >
            <div className="grid gap-3 md:grid-cols-[1fr_auto_1fr_auto_1fr_auto_1fr] md:items-center">
              <FlowNode label="Generator" detail="CSV + contract" />
              <span className="hidden md:block" aria-hidden="true">→</span>
              <FlowNode label="GCS" detail="raw object" tone="gcp" />
              <span className="hidden md:block" aria-hidden="true">→</span>
              <FlowNode label="BigQuery + dbt" detail="warehouse / marts" tone="gcp" />
              <span className="hidden md:block" aria-hidden="true">→</span>
              <FlowNode label="Looker Studio" detail="dashboard" tone="gcp" />
            </div>
          </ArchitectureFrame>

          <ArchitectureFrame
            title="AWS implementation"
            caption="S3とAthenaでstorage/computeを分離。Glue CatalogとParquet partitionを使います。"
          >
            <div className="grid gap-3 md:grid-cols-[1fr_auto_1fr_auto_1fr_auto_1fr] md:items-center">
              <FlowNode label="Generator" detail="CSV + contract" />
              <span className="hidden md:block" aria-hidden="true">→</span>
              <FlowNode label="S3 + Glue" detail="Parquet / catalog" tone="aws" />
              <span className="hidden md:block" aria-hidden="true">→</span>
              <FlowNode label="Athena + dbt" detail="lakehouse / marts" tone="aws" />
              <span className="hidden md:block" aria-hidden="true">→</span>
              <FlowNode label="Tableau Public" detail="dashboard" tone="aws" />
            </div>
          </ArchitectureFrame>

          <ArchitectureFrame
            title="Portfolio website"
            caption="BIの埋め込みURLは未確定。自然言語分析エージェントは後続実装です。"
          >
            <div className="grid gap-3 md:grid-cols-[1fr_auto_1fr_auto_1fr] md:items-center">
              <FlowNode label="Project docs" detail="facts / definitions" />
              <span className="hidden md:block" aria-hidden="true">→</span>
              <FlowNode label="Next.js 16" detail="App Router / TS / Tailwind" tone="shared" />
              <span className="hidden md:block" aria-hidden="true">→</span>
              <FlowNode label="Vercel" detail="static-first site" />
            </div>
          </ArchitectureFrame>
        </div>
      </Section>

      <Section>
        <SectionHeading
          eyebrow="Workflow"
          title="生成から公開までの処理順序"
          copy="ローカルでの契約・品質確認を先に行い、その後にクラウドtargetとBIへ展開します。"
        />
        <ol className="overflow-hidden rounded-card border border-border bg-surface">
          {workflow.map(([index, action, tool, detail]) => (
            <li
              key={index}
              className="grid gap-3 border-b border-border p-5 last:border-b-0 md:grid-cols-[50px_120px_180px_1fr] md:items-start"
            >
              <span className="font-mono text-xs text-terracotta">{index}</span>
              <span className="font-display font-semibold">{action}</span>
              <span className="font-mono text-xs leading-6 text-ink">{tool}</span>
              <span className="text-sm leading-7 text-ink-muted">{detail}</span>
            </li>
          ))}
        </ol>
      </Section>

      <Section className="border-y border-border bg-surface">
        <SectionHeading
          eyebrow="Technology usage"
          title="各技術の用途と選定理由"
        />
        <div className="grid gap-4 md:grid-cols-2">
          {technologies.map((technology) => (
            <Card key={technology.name}>
              <h2 className="font-mono text-sm font-semibold">{technology.name}</h2>
              <p className="mt-2 text-xs text-terracotta">{technology.role}</p>
              <dl className="mt-5 space-y-4 text-sm">
                <div className="grid grid-cols-[75px_1fr] gap-3">
                  <dt className="text-ink-faint">選定理由</dt>
                  <dd className="leading-7 text-ink-muted">{technology.reason}</dd>
                </div>
                <div className="grid grid-cols-[75px_1fr] gap-3">
                  <dt className="text-ink-faint">実装内容</dt>
                  <dd className="leading-7 text-ink-muted">{technology.implementation}</dd>
                </div>
              </dl>
            </Card>
          ))}
        </div>
      </Section>

      <Section>
        <SectionHeading eyebrow="Portability" title="論理共通・物理最適化のみクラウド別" />
        <div className="overflow-x-auto rounded-card border border-border bg-surface">
          <table className="w-full min-w-[760px] border-collapse text-left text-sm">
            <thead className="bg-surface-strong">
              <tr>
                <th className="p-4">区分</th>
                <th className="p-4">共通化するもの</th>
                <th className="p-4">クラウド別にするもの</th>
              </tr>
            </thead>
            <tbody className="[&_tr]:border-t [&_tr]:border-border [&_td]:p-4 [&_td]:align-top [&_td]:leading-7">
              <tr>
                <td className="font-semibold">Schema</td>
                <td>論理列名、型の意味、grain、key</td>
                <td>BigQuery NUMERIC / Athena DECIMAL、DDL</td>
              </tr>
              <tr>
                <td className="font-semibold">Transform</td>
                <td>dbt model、KPI、business rule</td>
                <td>money_cast、timestamp_cast、date macro</td>
              </tr>
              <tr>
                <td className="font-semibold">Physical</td>
                <td>保存対象と更新単位</td>
                <td>partition/cluster、Parquet/partition projection</td>
              </tr>
              <tr>
                <td className="font-semibold">Quality</td>
                <td>141 tests、reconciliation条件</td>
                <td>adapterごとの実行profile</td>
              </tr>
            </tbody>
          </table>
        </div>
      </Section>

      <Section className="bg-canvas-subtle">
        <div className="grid gap-6 md:grid-cols-[1fr_auto] md:items-start">
          <div>
            <p className="font-mono text-[11px] font-semibold uppercase tracking-[0.16em] text-terracotta">
              Roadmap
            </p>
            <h2 className="mt-3 font-display text-2xl font-semibold">自然言語分析AIエージェント</h2>
            <p className="mt-4 max-w-3xl text-sm leading-7 text-ink-muted">
              公開用martsを対象に、自然言語からSQLを生成・実行する機能を後続で実装予定です。read-only、対象martのallowlist、row limit、実行SQL表示を前提とします。現時点では未実装です。
            </p>
          </div>
          <Badge tone="amber">Not implemented</Badge>
        </div>
      </Section>
    </>
  );
}
