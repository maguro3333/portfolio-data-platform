# EC sample-data generator

`docs/decisions.md`と`docs/schema_design_detail.md`に基づき、GCP/AWSへ同一投入できるCore／Intermediate用の生CSVを生成する。

## Characteristics

- Python 3.9互換
- seed固定による再現可能な生成
- `smoke`（1,000 users／約5,000 sessions）と`full`（40,000 users／約220,000 sessions）
- 最大の`fact_events`はストリーム生成
- 金額計算は`Decimal`
- 各tableを`data/raw/<table>/part-00000.csv.gz`へ出力
- 全tableのprofileと品質検査結果だけを`data/reports/`へ出力
- Martは生成しない。Core／Intermediateから後続SQLで生成する

## Requirements

- Python 3.9.x
- macOS/Linux
- full生成時は、圧縮CSV作成と再読込による品質検査に十分な空き容量とメモリ

依存versionは`requirements.txt`へ固定している。生成器は`numpy`、`pandas`、`PyYAML`だけを使用し、不要なFaker／PyArrow依存は追加していない。

## Setup

リポジトリrootで実行する。

```bash
python3.9 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r generator/requirements.txt
```

## Smoke generation

初回は必ずsmokeを実行する。

```bash
python -m generator --scale smoke
```

既存の`data/raw/<table>`を置換するときだけ、明示的に`--overwrite`を付ける。

```bash
python -m generator --scale smoke --overwrite
```

成功時：

- `data/reports/profile.json`
- `data/reports/quality_report.md`
- `Quality status: PASS`

Claude Codeは生成CSV本体を読まず、上記2 reportだけを確認する。

```bash
sed -n '1,240p' data/reports/quality_report.md
python - <<'PY'
import json
from pathlib import Path

profile = json.loads(Path("data/reports/profile.json").read_text())
print(profile["quality_summary"])
for table, values in profile["tables"].items():
    print(table, values["row_count"], values["compressed_bytes"])
PY
```

## Full generation

smokeの品質検査がPASSし、件数・分布をClaude Code側で承認した後に実行する。

```bash
python -m generator --scale full --overwrite
```

`full`は約135万eventsを生成し、その後profile／品質検査のためgzip CSVをchunk再読込する。smokeより時間がかかる。

## Configuration

`config.yaml`に以下を集約している。

- seed、期間、scale別件数
- user/device/channel分布
- 季節係数、sale期間
- funnel到達目標
- cancellation／full refund
- price、discount、tax、shipping
- 30日attribution
- membership rank
- Public用小集団基準

一時的な件数変更でも、まず`config.yaml`をGit差分としてレビューする。CLI引数で任意件数を直接指定する方式は採用していない。

## Schema contract

`schema_contract.yaml`が生成CSVのtable名、列順、論理型、primary keyの単一契約である。

- BigQuery DDL：`sql/bigquery/01_core.sql`
- Athena DDL：`sql/athena/01_core.sql`

Athenaの`bridge_user_identity.valid_from_date`は物理partition補助列であり、論理契約には含めない。

## Output safety

- 出力先table directoryが存在すると、既定では停止する
- `--overwrite`指定時だけ生成済みtable directoryを削除して再作成する
- `data/raw/`は`.gitignore`対象
- 直接PIIは生成しない
- timestampはUTC、業務日付はJSTで導出
- 通貨はJPY、金額CSVは小数2桁

## Exit status

- 全品質check PASS：`0`
- 生成設定不正、schema不一致、品質check FAIL：非0

品質checkには次を含む。

- schema header
- primary key
- foreign key
- 注文明細／header金額整合
- recognized revenue
- campaign cost bounds
- attribution credit
- event数とsession集計
- purchase eventとorder照合
- nested funnel
