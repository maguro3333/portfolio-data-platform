# EC データ基盤ポートフォリオ(GCP / AWS 二刀流)

フリーランスのデータエンジニア(小田航平)による、案件受託向けのサンプルプロジェクトです。
同一の EC データモデルを **GCP(BigQuery ウェアハウス)と AWS(S3 + Athena レイクハウス)の2エンジン**で実装し、
**dbt** で共通の KPI・データ品質テストを通して結果を照合した実証を、ドキュメントとして公開しています。

> ポートフォリオサイト(このリポジトリの `web/`): デプロイ後に URL を掲載します。

## 何を示すプロジェクトか

- **論理モデルは共通・物理最適化のみクラウド別**という設計を、実際に動く形で実装
- ローカル(DuckDB)/ GCP(BigQuery)/ AWS(Athena)の **3エンジンで dbt build 141 テスト全通過・KPI 完全一致**
- GA4 準拠の行動ログ設計、購買データのディメンショナルモデリング、データマート設計、BI 連携
- Terraform による両クラウドの IaC、コストガード(BigQuery maximum bytes billed / Athena scan cutoff)

## サンプルデータ(合成)

EC の購買データ + GA4 準拠の行動ログ。生成AIではなく決定的な生成スクリプトで作成(seed 固定・再現可能)。

| 項目 | 規模 |
|---|---|
| 期間 | 2024-01-01 〜 2025-12-31(2年) |
| ユーザー / セッション / イベント | 40,000 / 220,000 / 1,350,000 |
| 注文 / 認識売上 | 10,800 / ¥124,544,333 |
| 購買ファネル(到達セッション) | view_item 100,100 → add_to_cart 27,940 → begin_checkout 16,940 → purchase 10,500 |

## アーキテクチャ概要

```
生成スクリプト(CSV) ─┬─ GCP: GCS → BigQuery(warehouse) → dbt-bigquery → Looker Studio
                     └─ AWS: S3  → Glue/Athena(Parquet lakehouse) → dbt-athena → Tableau Public
                        共通: raw(全列string)→ staging → intermediate(core)→ marts / dbt tests 141
```

- raw は全列 STRING で取り込み、staging で型・命名を整備(3エンジンで同一の staging 契約)
- 方言差は dbt マクロで吸収(`money_cast` / timestamp / `JOIN USING`→`ON` 等)
- マート: `mart_kpi_daily` / `mart_marketing_daily` / `mart_content_performance` / `mart_content_assists` / `mart_funnel_daily` / `mart_customer_rfm_snapshot`(内部)/ `mart_rfm_segment_daily`(公開)/ `mart_customer_cohort`

## リポジトリ構成

| ディレクトリ | 内容 |
|---|---|
| `generator/` | 合成データ生成スクリプト(Python、seed固定・品質レポート出力) |
| `sql/` | BigQuery / Athena の DDL |
| `dbt/` | dbt プロジェクト(staging / intermediate / marts、141 テスト、3エンジン target) |
| `terraform/gcp`, `terraform/aws` | 両クラウドの IaC |
| `scripts/` | GCS/S3 へのロード・Athena 外部テーブル作成 |
| `web/` | ポートフォリオサイト(Next.js + Tailwind、Vercel デプロイ想定) |
| `docs/` | 設計ドキュメント(アーキテクチャ / スキーマ / ダッシュボード設計 / 意思決定ログ) |

## 技術スタック

Python・SQL / dbt / BigQuery / S3・Glue・Athena / GCS / Terraform / DuckDB / Next.js・TypeScript・Tailwind CSS / Looker Studio・Tableau Public

## ロードマップ

- ダッシュボードの実埋め込み(Looker Studio / Tableau Public)
- 自然言語分析 AI エージェント(マート上の text-to-SQL)
- CI/CD(GitHub Actions)・オーケストレーション・Apache Iceberg デモ

---

Author: 小田航平 / Freelance Data Engineer
