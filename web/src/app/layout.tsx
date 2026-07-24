import type { Metadata } from "next";
import { IBM_Plex_Mono, Manrope, Noto_Sans_JP } from "next/font/google";
import { SiteFooter } from "@/components/layout/site-footer";
import { SiteHeader } from "@/components/layout/site-header";
import "./globals.css";

const notoSansJp = Noto_Sans_JP({
  variable: "--font-noto-sans-jp",
  subsets: ["latin"],
  display: "swap",
});

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
  display: "swap",
});

const ibmPlexMono = IBM_Plex_Mono({
  variable: "--font-ibm-plex-mono",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "小田航平 | Data Engineer",
    template: "%s | 小田航平",
  },
  description:
    "小田航平の経歴と、BigQuery・S3/Athena・dbtで実装したECデータ基盤サンプルの技術資料。",
  applicationName: "Kohei Oda Data Engineering Portfolio",
  authors: [{ name: "小田航平" }],
  creator: "小田航平",
  keywords: [
    "データエンジニア",
    "BigQuery",
    "Athena",
    "dbt",
    "GA4",
    "Looker Studio",
    "Tableau",
  ],
  openGraph: {
    type: "website",
    locale: "ja_JP",
    title: "小田航平 | Data Engineer",
    description:
      "経歴、システム構成、データ定義、dbt変換・品質テスト、BI設計を記載した技術ポートフォリオ。",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="ja"
      className={`${notoSansJp.variable} ${manrope.variable} ${ibmPlexMono.variable} antialiased`}
    >
      <body>
        <a
          href="#main-content"
          className="fixed left-4 top-4 z-[100] -translate-y-24 rounded-lg bg-dark-canvas px-4 py-3 text-sm font-semibold text-dark-text transition-transform focus:translate-y-0"
        >
          本文へ移動
        </a>
        <SiteHeader />
        <main id="main-content">{children}</main>
        <SiteFooter />
      </body>
    </html>
  );
}
