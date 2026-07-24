import type { ReactNode } from "react";

export function Section({
  children,
  className = "",
  id,
}: {
  children: ReactNode;
  className?: string;
  id?: string;
}) {
  return (
    <section id={id} className={`px-5 py-12 md:px-8 md:py-16 lg:py-20 ${className}`}>
      <div className="mx-auto max-w-[1200px]">{children}</div>
    </section>
  );
}

export function SectionHeading({
  eyebrow,
  title,
  copy,
}: {
  eyebrow: string;
  title: string;
  copy?: string;
}) {
  return (
    <div className="mb-8 max-w-3xl md:mb-10">
      <p className="mb-3 font-mono text-[11px] font-semibold uppercase tracking-[0.16em] text-terracotta">
        {eyebrow}
      </p>
      <h2 className="font-display text-2xl font-semibold leading-tight tracking-[-0.02em] md:text-3xl">
        {title}
      </h2>
      {copy ? (
        <p className="mt-4 max-w-2xl text-pretty text-sm leading-7 text-ink-muted md:text-base">
          {copy}
        </p>
      ) : null}
    </div>
  );
}
