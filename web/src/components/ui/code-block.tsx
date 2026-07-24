export function CodeBlock({
  filename,
  children,
}: {
  filename: string;
  children: string;
}) {
  return (
    <figure className="overflow-hidden rounded-[14px] border border-dark-border bg-dark-canvas shadow-float">
      <figcaption className="flex items-center justify-between border-b border-dark-border px-5 py-3 font-mono text-xs text-dark-muted">
        <span>{filename}</span>
        <span>SQL / Jinja</span>
      </figcaption>
      <pre className="overflow-x-auto p-5 font-mono text-[13px] leading-7 text-dark-text">
        <code>{children}</code>
      </pre>
    </figure>
  );
}
