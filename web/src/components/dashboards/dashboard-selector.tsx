"use client";

import { useState } from "react";
import type { DashboardDefinition } from "@/lib/site-data";
import { Badge } from "@/components/ui/badge";

export function DashboardSelector({
  dashboards,
}: {
  dashboards: readonly DashboardDefinition[];
}) {
  const [selectedId, setSelectedId] = useState(dashboards[0]?.id ?? "");
  const selected =
    dashboards.find((dashboard) => dashboard.id === selectedId) ?? dashboards[0];

  if (!selected) {
    return null;
  }

  return (
    <div className="grid gap-6">
      <div className="rounded-card border border-border bg-surface p-5">
        <label htmlFor="dashboard-select" className="block text-sm font-semibold">
          表示するダッシュボード
        </label>
        <select
          id="dashboard-select"
          value={selected.id}
          onChange={(event) => setSelectedId(event.target.value)}
          className="mt-3 min-h-12 w-full rounded-[10px] border border-border-strong bg-surface-strong px-4 text-sm text-ink md:max-w-xl"
        >
          {dashboards.map((dashboard) => (
            <option key={dashboard.id} value={dashboard.id}>
              {dashboard.title}
            </option>
          ))}
        </select>
      </div>

      <article className="overflow-hidden rounded-frame border border-border bg-surface">
        <header className="grid gap-4 border-b border-border p-5 md:grid-cols-[1fr_auto] md:items-start md:p-6">
          <div>
            <p className="font-mono text-[10px] uppercase tracking-[0.12em] text-terracotta">
              {selected.tool}
            </p>
            <h2 className="mt-2 font-display text-2xl font-semibold">{selected.title}</h2>
            <p className="mt-3 max-w-3xl text-sm leading-7 text-ink-muted">
              {selected.description}
            </p>
          </div>
          <Badge tone="amber">{selected.status}</Badge>
        </header>

        <div className="paper-grid flex min-h-[420px] items-center justify-center border-b border-border bg-canvas p-6 md:min-h-[560px]">
          <div className="max-w-md rounded-card border border-border bg-surface p-6 text-center">
            <p className="font-mono text-[11px] uppercase tracking-[0.12em] text-terracotta">
              Embed placeholder
            </p>
            <p className="mt-3 text-sm leading-7 text-ink-muted">
              {selected.tool}の公開URL確定後、この領域へ選択中のダッシュボードを遅延読み込みします。
            </p>
          </div>
        </div>

        <div className="grid gap-6 p-5 md:grid-cols-2 md:p-6">
          <section aria-labelledby="source-marts-title">
            <h3 id="source-marts-title" className="text-sm font-semibold">
              参照mart
            </h3>
            <ul className="mt-3 space-y-2">
              {selected.marts.map((mart) => (
                <li
                  key={mart}
                  className="rounded-lg border border-border bg-canvas px-3 py-2 font-mono text-xs"
                >
                  {mart}
                </li>
              ))}
            </ul>
          </section>
          <section aria-labelledby="metrics-title">
            <h3 id="metrics-title" className="text-sm font-semibold">
              主要指標
            </h3>
            <ul className="mt-3 flex flex-wrap gap-2">
              {selected.metrics.map((metric) => (
                <li
                  key={metric}
                  className="rounded-full bg-canvas-subtle px-3 py-2 text-xs text-ink-muted"
                >
                  {metric}
                </li>
              ))}
            </ul>
          </section>
        </div>
      </article>
    </div>
  );
}
