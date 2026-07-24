import Link from "next/link";
import { navItems } from "@/lib/site-data";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-border bg-canvas/95 backdrop-blur-sm">
      <div className="mx-auto flex h-[72px] max-w-[1200px] items-center justify-between px-5 md:px-8">
        <Link href="/" className="flex items-center gap-3" aria-label="小田航平 ホーム">
          <span className="flex size-10 items-center justify-center rounded-lg bg-dark-canvas font-display text-sm font-bold text-dark-text">
            KO
          </span>
          <span className="hidden leading-tight sm:block">
            <span className="block font-display text-sm font-semibold">Kohei Oda</span>
            <span className="block font-mono text-[9px] uppercase tracking-[0.12em] text-ink-muted">
              Data Engineer
            </span>
          </span>
        </Link>

        <nav className="hidden items-center gap-1 xl:flex" aria-label="メインナビゲーション">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-lg px-3 py-2 text-sm font-medium text-ink-muted transition-colors hover:bg-surface hover:text-ink"
            >
              {item.label}
            </Link>
          ))}
          {/* TODO: Replace the placeholder after the public repository URL is fixed. */}
          <a
            href="#"
            aria-label="GitHub（リンク準備中）"
            title="GitHub URLは準備中です"
            className="ml-2 rounded-[10px] border border-border-strong px-4 py-2.5 text-sm font-semibold text-ink-muted"
          >
            GitHub
          </a>
        </nav>

        <details className="relative xl:hidden">
          <summary className="cursor-pointer list-none rounded-lg border border-border-strong px-4 py-2 text-sm font-semibold">
            Menu
          </summary>
          <nav
            className="absolute right-0 top-12 w-[min(82vw,320px)] rounded-card border border-border bg-surface p-3 shadow-float"
            aria-label="モバイルナビゲーション"
          >
            {navItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="block rounded-lg px-4 py-3 text-sm font-medium hover:bg-canvas-subtle"
              >
                {item.label}
              </Link>
            ))}
          </nav>
        </details>
      </div>
    </header>
  );
}
