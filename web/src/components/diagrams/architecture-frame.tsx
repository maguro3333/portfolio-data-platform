import type { ReactNode } from "react";

export function ArchitectureFrame({
  title,
  children,
  caption,
}: {
  title: string;
  children: ReactNode;
  caption: string;
}) {
  return (
    <figure className="rounded-frame border border-border-strong bg-surface-strong p-5 shadow-float md:p-8">
      <div className="mb-6 flex items-center justify-between gap-4 border-b border-border pb-4">
        <h3 className="font-display text-lg font-semibold">{title}</h3>
        <span className="font-mono text-[10px] uppercase tracking-[0.14em] text-ink-faint">
          Logical flow
        </span>
      </div>
      {children}
      <figcaption className="mt-6 border-t border-border pt-4 text-sm leading-6 text-ink-muted">
        {caption}
      </figcaption>
    </figure>
  );
}

export function FlowNode({
  label,
  detail,
  tone = "neutral",
}: {
  label: string;
  detail: string;
  tone?: "gcp" | "aws" | "shared" | "neutral";
}) {
  const tones = {
    gcp: "border-sage bg-sage-soft",
    aws: "border-amber bg-amber-soft",
    shared: "border-terracotta bg-terracotta-soft",
    neutral: "border-border-strong bg-surface",
  };

  return (
    <div className={`rounded-xl border p-4 ${tones[tone]}`}>
      <p className="font-display text-sm font-semibold">{label}</p>
      <p className="mt-1 text-xs leading-5 text-ink-muted">{detail}</p>
    </div>
  );
}
