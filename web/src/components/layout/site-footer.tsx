import Link from "next/link";

export function SiteFooter() {
  return (
    <footer className="border-t border-dark-border bg-dark-canvas px-5 py-14 text-dark-text md:px-8">
      <div className="mx-auto grid max-w-[1200px] gap-10 md:grid-cols-2 md:items-end">
        <div>
          <div className="flex items-center gap-3">
            <span className="flex size-11 items-center justify-center rounded-lg border border-dark-border font-display text-sm font-bold">
              KO
            </span>
            <div>
              <p className="font-display font-semibold">小田航平 / Kohei Oda</p>
              <p className="mt-1 text-sm text-dark-muted">Freelance Data Engineer</p>
            </div>
          </div>
          <p className="mt-6 max-w-xl text-sm leading-7 text-dark-muted">
            経歴と、GCP/AWSで実装したECデータ基盤サンプルの構成・データ定義・検証結果を掲載しています。
          </p>
        </div>
        <div className="md:text-right">
          <div className="flex flex-wrap gap-x-5 gap-y-3 md:justify-end">
            <Link href="/architecture" className="text-sm hover:text-dark-accent">
              Architecture
            </Link>
            <Link href="/data-pipeline" className="text-sm hover:text-dark-accent">
              Data & Pipeline
            </Link>
            <Link href="/dashboards" className="text-sm hover:text-dark-accent">
              Dashboards
            </Link>
            <Link href="/ai-analyst" className="text-sm hover:text-dark-accent">
              AI Analyst
            </Link>
          </div>
          <p className="mt-7 font-mono text-[10px] uppercase tracking-[0.12em] text-dark-muted">
            Synthetic data · Built with Next.js
          </p>
        </div>
      </div>
    </footer>
  );
}
