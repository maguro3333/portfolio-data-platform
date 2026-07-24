import type { ReactNode } from "react";

export function PageHero({
  eyebrow,
  title,
  copy,
  meta,
  aside,
}: {
  eyebrow: string;
  title: string;
  copy: string;
  meta?: readonly string[];
  aside?: ReactNode;
}) {
  return (
    <header className="border-b border-border bg-surface px-5 py-10 md:px-8 md:py-12">
      <div className="mx-auto grid max-w-[1200px] gap-8 lg:grid-cols-12 lg:items-start">
        <div className={aside ? "lg:col-span-8" : "lg:col-span-9"}>
          <p className="font-mono text-[11px] font-semibold uppercase tracking-[0.16em] text-terracotta">
            {eyebrow}
          </p>
          <h1 className="mt-3 font-display text-3xl font-semibold tracking-[-0.025em] md:text-4xl">
            {title}
          </h1>
          <p className="mt-4 max-w-[48rem] text-pretty text-base leading-8 text-ink-muted">
            {copy}
          </p>
          {meta ? (
            <ul className="mt-5 flex flex-wrap gap-x-5 gap-y-2 text-xs text-ink-faint">
              {meta.map((item) => (
                <li key={item} className="before:mr-2 before:text-terracotta before:content-['•']">
                  {item}
                </li>
              ))}
            </ul>
          ) : null}
        </div>
        {aside ? <div className="lg:col-span-4">{aside}</div> : null}
      </div>
    </header>
  );
}
