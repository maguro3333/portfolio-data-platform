# ポートフォリオサイト 詳細設計（ケーススタディ型・改訂版）

> 対象: 小田航平 ECデータ基盤ポートフォリオ
>
> 正とする方針: `docs/site_revision_brief.md`
>
> ステータス: 実装・レビュー用

## 1. 目的と閲覧者

目的は、フリーランスのデータエンジニア案件を検討する採用担当、エージェント、クライアントが、次の点を判断できるようにすること。

1. 本人の経験領域と担当可能な工程
2. サンプルプロジェクトを作った意図
3. GCP版・AWS版の構成と実装順序
4. データ粒度、型、変換、martの設計内容
5. 品質テストとクロスエンジン照合の範囲
6. BIが参照するmartと指標

本サイトは宣伝用ランディングページではなく、経歴と技術成果物を確認するためのドキュメント／ケーススタディとして構成する。

## 2. 情報設計の原則

### 2.1 事実を先に置く

- 各ページの冒頭に、ページ名、対象、実装範囲、確認できる内容を置く。
- 抽象的なキャッチコピーやスローガンでファーストビューを消費しない。
- 数値には対象、期間、単位、検証状態を付ける。
- 実務経験とポートフォリオ内での構築経験を区別する。
- 未実装・URL未確定の機能は`Not implemented`または`Embed URL pending`と表示する。

### 2.2 読む順序

推奨順序は次のとおり。

1. Home: サイトの目次
2. About: 経歴と対応領域
3. Architecture: 実装意図、構成、workflow
4. Data & Pipeline: schema、変換、mart、品質
5. Dashboards: martの利用先
6. AI Analyst: martへの自然言語queryと生成SQL

Contactは当面非公開扱いとし、グローバルナビ、sitemapから除外する。

### 2.3 主張と根拠

| 掲載内容 | 根拠 |
|---|---|
| データ規模・期間 | `docs/decisions.md`, generator profile |
| 論理列・型・key | `generator/schema_contract.yaml` |
| 物理設計・コスト | `docs/schema_design_detail.md` |
| AWS構成・選定理由 | `docs/architecture_review_market_fit.md` |
| ダッシュボード・mart対応 | `docs/dashboard_design.md`, dbt models |
| dbt model/test件数 | 実装済みdbt projectとtarget別build結果 |

## 3. デザインシステム

### 3.1 カラー

ライト基調を正式テーマとする。色は情報分類と状態表示に限定して使用する。

#### Foundation

| Token | HEX | 用途 |
|---|---:|---|
| `canvas` | `#F5EFE5` | ページ背景 |
| `canvas-subtle` | `#EDE4D8` | 表・セクション背景 |
| `surface` | `#FFF9F1` | カード、ヘッダー |
| `surface-strong` | `#FFFCF7` | table header、前面要素 |
| `ink` | `#29231F` | 本文・見出し |
| `ink-muted` | `#6B6058` | 説明文 |
| `ink-faint` | `#8A7C71` | metadata |
| `border` | `#D8C9BA` | 通常罫線 |
| `border-strong` | `#BDAA99` | hover・主要罫線 |

#### Accent

| Token | HEX | 用途 |
|---|---:|---|
| `terracotta` | `#A9462C` | section label、primary link |
| `terracotta-hover` | `#873622` | hover |
| `terracotta-soft` | `#F1D6C9` | tag背景 |
| `amber` | `#C97819` | AWS、pending |
| `amber-soft` | `#F6E0BA` | AWS/pending背景 |
| `sage` | `#3F665A` | GCP、passed |
| `sage-soft` | `#D8E5DE` | GCP/passed背景 |
| `blue` | `#426A87` | focus、情報link |
| `danger` | `#A23A3A` | error |

#### Dark section

| Token | HEX | 用途 |
|---|---:|---|
| `dark-canvas` | `#211D1A` | footer、検証section |
| `dark-surface` | `#2C2723` | dark card |
| `dark-border` | `#4D443D` | dark罫線 |
| `dark-text` | `#F7EFE4` | dark本文 |
| `dark-muted` | `#C8B8A8` | dark補足 |
| `dark-accent` | `#EE9A62` | dark強調 |

GCPはsage、AWSはamber、共通dbt層はterracottaで表す。色だけに依存せず、名称と用途を併記する。

### 3.2 タイポグラフィ

- 和文/UI: Noto Sans JP
- 欧文・数字: Manrope
- コード・table名・column名: IBM Plex Mono
- fallback: system-ui, -apple-system, Hiragino Sans, Yu Gothic, sans-serif

推奨スケール:

| Style | Desktop | Mobile | 用途 |
|---|---:|---:|---|
| Page title | 36px | 30px | ページ名 |
| Section title | 30px | 24px | 主section |
| Subsection | 20px | 18px | table/card見出し |
| Body | 16px | 16px | 本文 |
| Table | 13〜14px | 横scroll | schema/mart |
| Metadata | 11〜12px | 11〜12px | label、status |

大きなdisplay見出しは使用しない。本文line-heightは1.7〜1.8、長文幅は48rem以内。

### 3.3 レイアウト

- 最大幅: 1200px
- 左右余白: desktop 32px / mobile 20px
- ページヘッダー: 40〜48px上下
- section: desktop 64〜80px / mobile 48px
- 8px基準のspacing
- 12列grid
- schema/mart表はdesktopで表、mobileは横scroll

### 3.4 形状

- card radius: 16px
- diagram/embed radius: 20px
- button/input radius: 10px
- 影は浮遊要素だけに使用
- 通常の情報区切りは1px border
- 大きなgradient、glass、装飾animationは使用しない

## 4. 共通コンポーネント

### 4.1 Header

- 左: `KO`モノグラム、氏名、職種
- 右: Index / About / Architecture / Data & Pipeline / Dashboards / AI Analyst
- Contactは表示しない
- GitHubはURL確定までplaceholderと明示
- mobileはdetails/summaryによるmenu

### 4.2 Document page header

含める要素:

1. 英語のsection label
2. 事実ベースのページ名
3. 2〜4行の対象・内容説明
4. 期間、件数、status等のmetadata

除外する要素:

- キャッチコピー
- CTA button
- 大型イラスト
- 内容と無関係なKPI強調

### 4.3 Card

用途:

- Homeの目次
- 技術の用途・選定理由
- layer、responsibility、fact

カードは「見出し／説明／metadata」を基本とし、カード全体をlinkにする場合は遷移先を明示する。

### 4.4 Table

用途:

- skillと担当内容
- 論理型mapping
- core table定義
- mart grainと問い
- portability境界

要件:

- `<table>`を使用する
- headerを明示
- mobileは横scroll
- table名、column名、型はmono font
- 1セルへ長文を詰めすぎない

### 4.5 Architecture frame

- GCP、AWS、Webを別figureにする
- nodeへサービス名と用途を併記
- desktopは横flow、mobileは縦並び
- captionへ構成の前提を記載

### 4.6 Dashboard selector

- native `<select>`を使用
- Client Componentはselectorと選択状態だけ
- 選択結果ごとにtitle、tool、status、説明、embed枠、参照mart、主要指標を更新
- URL未確定時は実iframeを作らずplaceholderを表示
- URL確定後は遅延読み込みと外部表示linkを追加

### 4.7 Status badge

使用例:

- `Passed`
- `Embed URL pending`
- `Not implemented`
- `No personal data`

価値判断ではなく事実の状態だけを示す。

## 5. ページ別構成

### 5.1 Home `/`

目的: サイトマップ。

順序:

1. compact header
   - 氏名・職種
   - 何のサイトか
   - サンプルの対象範囲
2. Contents
   - About
   - Architecture
   - Data & Pipeline
   - Dashboards
   - 各linkに「何が確認できるか」と内容のkeywords
3. Project at a glance
   - 期間
   - データ規模
   - GCP/AWS構成
   - 26 models
   - 141 tests
   - BI status
4. Implementation scope
   - 生成・契約
   - クラウド・変換
   - 分析・公開

Homeにはスローガン、featured case study、CTA stripを置かない。

### 5.2 About `/about`

目的: 経歴と担当可能範囲。

順序:

1. 氏名、職種、要約、公開上の注記
2. 職務要約
3. skill table
   - Data engineering
   - Measurement
   - BI
   - Portfolio work
4. 略歴
   - 所属
   - 期間
   - 主な担当
5. 担当できる工程
   - 要件・計測
   - モデル
   - 実装・品質
   - BI・利用支援
6. 本サンプルで追加検証した領域

職務経歴書PDFは公開しない。略歴は公開可能な所属、期間、担当範囲だけを掲載する。

### 5.3 Architecture `/architecture`

目的: デモの全体像、意図、処理順序、技術用途を示す。

順序:

1. 対象構成と実装範囲
2. 実装意図
   - GCP実務を基点にAWS構成を比較
   - 論理共通・物理別
   - 無料枠とコストガード
3. system diagram
   - GCP: generator → GCS → BigQuery/dbt → Looker Studio
   - AWS: generator → S3/Glue → Athena/dbt → Tableau Public
   - Web: docs → Next.js → Vercel
4. workflow
   - Generate → Load → Transform → Validate → Visualize → Publish
5. technology usage
   - role、selection reason、implementation
6. portability table
7. AI Analystへの導線と実装済みguardrail

AI Analystは公開7 martだけを参照し、Claude APIはステートレスなサーバープロキシ、ParquetとDuckDB-WASMはブラウザ内実行であることを記載する。SELECT/WITH限定、row limit、rate limitも明記する。

### 5.4 Data & Pipeline `/data-pipeline`

目的: 元データの定義とmart化の内容を示す。

順序:

1. dataset期間・規模・主要値
2. logical type mapping
3. core table definitions
   - table
   - 種別
   - grain
   - key
   - 主要column/type
   - 用途
4. layer processing
   - raw
   - staging
   - intermediate/core
   - marts
5. mart definitions
   - mart名
   - grain
   - 答える問い
   - consumer
6. quality and reconciliation

正式な全column契約は`generator/schema_contract.yaml`を正とし、サイトには採用判断に必要な主要列を掲載する。

### 5.5 Dashboards `/dashboards`

目的: BIとsource martの対応を示す。

順序:

1. 対象6画面とembed status
2. selectによるdashboard切替
3. 選択中dashboard
   - tool
   - 説明
   - embed / placeholder
   - 参照mart
   - 主要指標
4. mart lineage table
5. 共通指標定義

対象:

| Dashboard | Mart |
|---|---|
| 全体KPI | `mart_kpi_daily` |
| Marketing | `mart_marketing_daily` |
| Content | `mart_content_performance`, `mart_content_assists` |
| RFM | `mart_rfm_segment_daily` |
| Cohort | `mart_customer_cohort` |
| Funnel | `mart_funnel_daily` |

### 5.6 Contact `/contact`

- mailto方式
- グローバルナビ非表示
- sitemap非掲載
- page metadata `noindex`
- robots `Disallow`
- 環境変数を優先し、fallbackは分割文字列から生成

### 5.7 AI Analyst `/ai-analyst`

- 公開7 martへ自然言語で問い合わせる。
- Anthropic tool useで`run_sql`を呼び出す。
- Next.js Node runtimeはClaude呼び出しとSQL検証だけを行い、DuckDB-WASMと公開Parquetはブラウザ内で実行する。
- UIは質問、sample question、回答、生成SQL、結果tableで構成する。
- SELECT/WITH限定、mart allowlist、1,000行上限、先頭50行表示とする。
- 合成データであることと、生成SQL・解釈の確認が必要であることを明記する。

## 6. Next.js実装構成

```text
web/src/
├── app/
│   ├── page.tsx
│   ├── about/page.tsx
│   ├── architecture/page.tsx
│   ├── data-pipeline/page.tsx
│   ├── dashboards/page.tsx
│   ├── ai-analyst/page.tsx
│   ├── api/analyst/route.ts
│   ├── contact/page.tsx
│   ├── layout.tsx
│   ├── globals.css
│   ├── robots.ts
│   └── sitemap.ts
├── components/
│   ├── analyst/analyst-chat.tsx
│   ├── dashboards/dashboard-selector.tsx
│   ├── diagrams/architecture-frame.tsx
│   ├── layout/
│   ├── sections/
│   └── ui/
└── lib/
    ├── agent/
    └── site-data.ts
```

- Server Componentを基本とする。
- `"use client"`はdashboard selectorとanalyst chatへ限定する。
- MDXは導入せず、事実データを`site-data.ts`へ型付きで集約する。
- Tailwind v4は`globals.css`の`@theme inline`でtokenを定義する。
- fontはnext/fontでCSS variableへ接続する。

## 7. コピー規約

### 7.1 使用する文体

- 一人称または主語を省略した説明文
- 「〜を実装した」「〜を使用する」「〜を検証した」
- 対象、理由、処理、結果を分ける
- 英語の技術語は正式名称またはコード上の名称を使う

### 7.2 使用しない表現

- 抽象的なスローガン
- 工程を比喩化したキャッチコピー
- 実装内容を説明しない情緒的なブランド表現
- 「革新的」「最先端」「完璧」
- 根拠のない「高品質」「実践的」「モダン」

### 7.3 事実の区別

| 状態 | 表現 |
|---|---|
| 実務経験 | 「業務で担当」「実務経験」 |
| 本サンプルで実装 | 「本プロジェクトで実装」 |
| 検証済み | 対象target、test件数、結果を記載 |
| 設計済み・未公開 | 「設計済み」「URL未確定」 |
| 将来実装 | 「Roadmap」「未実装」 |

### 7.4 表記

- `GA4準拠`だけで終えず、「GA4 BigQuery Exportを参考にした合成行動ログ」と書く。
- `3エンジン`はDuckDB / BigQuery / Athenaを併記する。
- `2クラウド`と`3 SQL engines`を混同しない。
- recognized revenueは税・送料を含めない主指標であることを明記する。
- test件数は`dbt build 141 tests passed`の対象targetを併記する。

## 8. 公開前確認

1. `NEXT_PUBLIC_SITE_URL`
2. Contact email
3. GitHub URL
4. Looker Studio / Tableau Public URL
5. dashboard embed permissionとfallback
6. target別dbt buildの最終実行日・commit SHA
7. 公開する職歴情報の範囲
8. 料金・無料枠記載の確認日
