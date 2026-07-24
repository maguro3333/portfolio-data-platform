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
```

## Validation

```bash
npm run lint
npm run build
```

Contactページはグローバルナビとsitemapから除外し、ページmetadataの`noindex`と`robots.txt`の`Disallow`を設定しています。

ダッシュボード公開URLとGitHub URLは未確定のため、現時点ではComing soon / placeholder表示です。
