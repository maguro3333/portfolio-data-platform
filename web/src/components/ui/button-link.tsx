import Link from "next/link";
import type { ReactNode } from "react";

type ButtonLinkProps = {
  href: string;
  children: ReactNode;
  variant?: "primary" | "secondary" | "dark";
  className?: string;
};

const variants = {
  primary:
    "bg-terracotta text-white hover:bg-terracotta-hover border-terracotta",
  secondary:
    "bg-transparent text-ink hover:bg-surface-strong border-border-strong",
  dark: "bg-dark-text text-dark-canvas hover:bg-white border-dark-text",
};

export function ButtonLink({
  href,
  children,
  variant = "primary",
  className = "",
}: ButtonLinkProps) {
  const classes = `inline-flex min-h-12 items-center justify-center gap-2 rounded-[10px] border px-5 py-3 text-sm font-semibold transition-colors ${variants[variant]} ${className}`;

  if (href.startsWith("/")) {
    return (
      <Link href={href} className={classes}>
        {children}
        <span aria-hidden="true">→</span>
      </Link>
    );
  }

  return (
    <a href={href} className={classes}>
      {children}
      <span aria-hidden="true">→</span>
    </a>
  );
}
