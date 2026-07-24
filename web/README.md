# Kohei Oda — Data Engineering Portfolio

Next.js App Router、TypeScript、Tailwind CSS v4で実装したポートフォリオサイトです。

## Local development

```bash
cp .env.example .env.local
npm run dev
```

`.env.local`には公開URLと連絡先を設定します。

```text
NEXT_PUBLIC_SITE_URL=https://your-domain.example
NEXT_PUBLIC_CONTACT_EMAIL=your-address@example.com
ANTHROPIC_API_KEY=your-server-side-api-key
AGENT_MODEL=claude-sonnet-5
```

## Validation

```bash
npm run lint
npm run build
```

Contactページはグローバルナビとsitemapから除外し、ページmetadataの`noindex`と`robots.txt`の`Disallow`を設定しています。

ダッシュボード公開URLとGitHub URLは未確定のため、現時点ではComing soon / placeholder表示です。

## AI Analyst

`/ai-analyst`は、Anthropicのtool useでSQLを生成し、サーバーで安全性を検証したうえで、ブラウザ内のDuckDB-WASMから`public/marts/*.parquet`をread-only参照します。API routeはClaude呼び出しだけを担い、DuckDBやParquetをサーバーバンドルへ含めません。

- `ANTHROPIC_API_KEY`はサーバー側だけで使用します。
- `AGENT_MODEL`は任意です。未指定時は`claude-sonnet-5`です。
- SQLはSELECT/WITH、公開7 martだけに制限しています。
- サーバーレスのrate limitはベストエフォートです。恒久的な費用上限はAnthropic Console側のAPIキーspend limitで設定してください。
