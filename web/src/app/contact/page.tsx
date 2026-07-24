import type { Metadata } from "next";
import { PageHero } from "@/components/sections/page-hero";
import { Section, SectionHeading } from "@/components/layout/section";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";

export const metadata: Metadata = {
  title: "Contact",
  description: "小田航平へのデータ基盤・計測・BI案件のご相談。",
  robots: {
    index: false,
    follow: false,
    nocache: true,
  },
};

function getContactAddress() {
  // Real address is injected via NEXT_PUBLIC_CONTACT_EMAIL (Vercel env) only.
  // Never hardcode the address here — this file is public in the repo.
  return process.env.NEXT_PUBLIC_CONTACT_EMAIL ?? "contact@example.com";
}

export default function ContactPage() {
  const email = getContactAddress();
  const mailto = `mailto:${email}?subject=${encodeURIComponent(
    "データ基盤案件のご相談",
  )}`;

  return (
    <>
      <PageHero
        eyebrow="Contact"
        title="連絡先"
        copy="データ基盤、Web計測、BIに関する案件連絡用のページです。相談概要と希望時期をメールでお送りください。"
        meta={["Private preview", "noindex", "グローバルナビ非掲載"]}
      />

      <Section>
        <SectionHeading
          eyebrow="Engagement fit"
          title="このような分断から、ご相談いただけます。"
        />
        <div className="grid gap-5 md:grid-cols-3">
          {[
            ["計測と購買がつながらない", "GA4/GTMイベントと基幹注文を同じ分析軸へ接続したい。"],
            ["KPIの数字が部署で違う", "定義、粒度、例外処理を揃え、dbtで品質を保証したい。"],
            ["BIが見るだけで終わる", "利用者の問いから、施策判断につながる画面へ再設計したい。"],
          ].map(([title, copy]) => (
            <Card key={title}>
              <h2 className="font-display text-xl font-semibold">{title}</h2>
              <p className="mt-4 text-sm leading-7 text-ink-muted">{copy}</p>
            </Card>
          ))}
        </div>
      </Section>

      <Section className="bg-canvas-subtle">
        <div className="grid gap-10 lg:grid-cols-12 lg:items-center">
          <div className="lg:col-span-7">
            <Badge tone="terracotta">Email</Badge>
            <h2 className="mt-5 font-display text-3xl font-semibold">
              相談概要と希望時期をお送りください。
            </h2>
            <p className="mt-5 max-w-2xl text-base leading-8 text-ink-muted">
              会社名・ご担当者名、現在の課題、対象データや利用ツール、希望時期が分かる範囲で十分です。機密情報は初回メールへ記載しないでください。
            </p>
          </div>
          <div className="rounded-card border border-border bg-surface p-7 lg:col-span-5">
            <p className="font-mono text-[10px] uppercase tracking-[0.14em] text-ink-faint">
              Contact address
            </p>
            <p className="mt-4 break-all font-mono text-sm">{email}</p>
            <a
              href={mailto}
              className="mt-6 inline-flex min-h-12 w-full items-center justify-center rounded-[10px] bg-terracotta px-5 py-3 text-sm font-semibold text-white transition-colors hover:bg-terracotta-hover"
            >
              メールを作成する
              <span className="ml-2" aria-hidden="true">
                →
              </span>
            </a>
          </div>
        </div>
      </Section>

      <Section>
        <SectionHeading eyebrow="Next steps" title="ご連絡後の流れ" />
        <ol className="grid gap-4 md:grid-cols-3">
          {[
            ["01", "内容確認", "課題、スコープ、希望時期を確認します。"],
            ["02", "ヒアリング", "必要に応じて現状と期待成果を整理します。"],
            ["03", "進め方の相談", "対応範囲、成果物、期間について相談します。"],
          ].map(([number, title, copy]) => (
            <li key={number} className="rounded-card border border-border bg-surface p-6">
              <span className="font-mono text-xs text-terracotta">{number}</span>
              <h2 className="mt-4 font-display text-xl font-semibold">{title}</h2>
              <p className="mt-3 text-sm leading-7 text-ink-muted">{copy}</p>
            </li>
          ))}
        </ol>
      </Section>
    </>
  );
}
