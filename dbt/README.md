# EC portfolio dbt project

Generatorが作成したgzip CSVをDuckDBで読み、staging → intermediate → martsを構築する。ローカルで分析ロジックと品質テストを確定した後、BigQuery／Athena adapterへ移植する前提である。

## Versions

- Python 3.9
- dbt-core 1.10.22
- dbt-duckdb 1.10.0

このディレクトリではpackage dependencyを使用しない。`packages.yml`は空で、外部packageのversion差やnetwork取得を避けている。

## Input

```text
../data/raw/<table>/part-00000.csv.gz
```

DuckDBでは`raw_relation` macroが`read_csv_auto(..., all_varchar=true)`を呼び、staging modelで明示的に型変換する。

BigQuery／Athenaでは同じmacroが`source('raw', table_name)`へ切り替わる。cloud側のraw tableとadapter profileは後続フェーズで設定する。

## Layering

```text
generator gzip CSV
  -> staging views
  -> intermediate tables
  -> internal/public/general marts
  -> BI exposures
```

### Staging

- generator/schema_contract.yamlと同じ列
- 型変換
- source/medium等の小文字正規化
- 空文字をNULLへ統一

### Intermediate

- `int_session_funnel`：同一session内で順序を必須とする4段階funnel
- `int_order_touchpoints`：注文前30日、session単位のattribution再計算
- `int_content_sessions`：content接触後の同一session行動
- `int_sessions_enriched`：new/existing/anonymous分類
- `int_order_items_agg`：order header照合

generator生成済みtouchpointは`stg_generated_order_touchpoints`として読み込むが、Martの正本には使用しない。dbtで再導出した結果とのreconciliation testにだけ使用する。

### Marts

- `mart_kpi_daily`
- `mart_marketing_daily`
- `mart_content_performance`
- `mart_content_assists`
- `mart_funnel_daily`
- `mart_customer_rfm_snapshot`：内部専用、顧客粒度
- `mart_rfm_segment_daily`：Public用、customers 10未満をSQLで除外
- `mart_customer_cohort`

## Business rules

- 主売上：`recognized_revenue`
- AOV／ROAS売上：税・送料を含めない商品純売上
- cancelled/refunded：recognized revenue 0
- attribution：30日、session単位、last non-directとlinear
- attribution credit：order/modelごとに1.000000
- RFM：月末snapshot内のquintile
- Public：customers >= 10
- 期間：2024-01-01～2025-12-31

## Local setup

リポジトリrootで既存venvを有効化する。

```bash
cd /Users/oda/portfolio-data-platform
source .venv/bin/activate
python -m pip install "dbt-core==1.10.22" "dbt-duckdb==1.10.0"
```

データ未生成の場合：

```bash
python -m generator --scale smoke
```

dbtは`dbt/`から実行する。相対raw pathがこのworking directoryを前提とするためである。

```bash
cd /Users/oda/portfolio-data-platform/dbt
dbt debug --profiles-dir .
dbt parse --profiles-dir .
dbt build --profiles-dir .
```

既にfull dataがある場合も同じコマンドを使う。

## Focused commands

```bash
# stagingだけ
dbt build --profiles-dir . --select path:models/staging

# attributionとdownstream
dbt build --profiles-dir . --select int_order_touchpoints+

# RFM
dbt build --profiles-dir . --select mart_customer_rfm_snapshot+

# cohort
dbt build --profiles-dir . --select mart_customer_cohort

# singular tests
dbt test --profiles-dir . --select test_type:singular

# docs
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

## Expected validation

`dbt build`で少なくとも次を確認する。

- source CSVのschema headerとstaging型
- PK/FK/accepted values
- order itemとheader金額
- recognized revenue policy
- purchase eventとorderの1対1照合
- session funnelの単調性
- attribution credit/revenue合計
- generator版touchpointとのorder単位照合
- KPI Martの日次order/revenueとCore一致
- marketing costの配賦後合計一致
- RFMにsnapshot後orderが含まれない
- Public RFMのcustomers >= 10
- cohortの率範囲、未成熟NULL、累積単調性

## Marketing cost allocation

広告費factは日×campaignでdeviceを持たない。一方、Marketing Martはdevice粒度を持つため、同日campaignのsession構成比でimpressions/clicks/costをdeviceへ配賦する。

- 費用をdevice行へ単純複製しない
- 最終device行へ丸め残差を寄せる
- `assert_marketing_cost_reconciliation`で元費用との一致を検査

これはmedia platformの実device別配信実績ではなく、BI粒度を成立させるためのallocationである。ダッシュボードで明記する。

## Portability

方言差は`macros/cross_database.sql`と`macros/raw_relation.sql`へ隔離する。

- raw relation
- timestamp/string cast
- date add
- month start/end/diff
- day diff
- safe divide

BigQuery/Athena移植時には以下を追加する。

1. adapter packageとcredential-free CI profile
2. source database/schema
3. materialization、partition、cluster/Iceberg config
4. adapter固有numeric cast
5. cloud別integration test

論理KPIとsingular testを共有し、物理最適化だけをtarget別に変更する。

## Safety

- `local.duckdb`と`target/`はGit管理しない
- `mart_customer_rfm_snapshot`をPublicへexportしない
- `profiles.yml`へcredentialを追加しない
- cloud queryはpartition/cost guard設定後に実行する
