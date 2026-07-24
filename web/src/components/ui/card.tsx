import type { ReactNode } from "react";

type CardProps = {
  children: ReactNode;
  className?: string;
  tone?: "default" | "subtle" | "dark";
};

const tones = {
  default: "border-border bg-surface text-ink",
  subtle: "border-border bg-canvas-subtle text-ink",
  dark: "border-dark-border bg-dark-surface text-dark-text",
};

export function Card({
  children,
  className = "",
  tone = "default",
}: CardProps) {
  return (
    <div className={`rounded-card border p-5 md:p-6 ${tones[tone]} ${className}`}>
      {children}
    </div>
  );
}
