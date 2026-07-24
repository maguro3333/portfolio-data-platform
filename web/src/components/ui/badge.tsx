import type { ReactNode } from "react";

export function Badge({
  children,
  tone = "terracotta",
}: {
  children: ReactNode;
  tone?: "terracotta" | "sage" | "amber" | "dark";
}) {
  const tones = {
    terracotta: "bg-terracotta-soft text-terracotta-hover",
    sage: "bg-sage-soft text-sage",
    amber: "bg-amber-soft text-ink",
    dark: "bg-dark-surface text-dark-accent",
  };

  return (
    <span
      className={`inline-flex rounded-full px-3 py-1 font-mono text-[11px] font-semibold uppercase tracking-[0.14em] ${tones[tone]}`}
    >
      {children}
    </span>
  );
}
