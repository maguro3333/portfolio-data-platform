# ECデータ基盤ポートフォリオ — プロジェクトルール

GCP版・AWS版のECデータ基盤を並行構築し、BIダッシュボードをポートフォリオサイトに埋め込む。コスト最優先(無料枠中心)。

## 役割分担(厳守)
- **Claude Code(司令塔)**: 基本方針・基本設計・実装の骨子を先に作る。最終判断を行う。
- **Codex(MCP)**: Claude Codeのたたき台をレビューし、詳細設計・詳細実装へ落とし込む。
- 順序は必ず「Claude Codeが先→Codexがレビュー/詳細化」。逆順(Codexにゼロから丸投げ)は禁止。

## トークン節約の運用(厳守)
- 大きな出力はファイルへ逃がす(`.artifacts/`)。全文でなく差分・サマリー・件数だけ読む。
- 作業把握は `git status --short` / `git diff --stat` から。全文再説明しない。
- CLI出力は最初から絞る(`--format`, `--query`, `--jq`, dry-run bytes 等)。
- 実装・DDL・データ生成コードなど分量の出る作業はCodexに書かせ、Claude Codeは差分レビューに徹する。
- 背景の再掲は不要。決定事項は本ファイルと `docs/` を参照する。

## コスト安全策(有料化しうる操作は事前相談)
- BigQuery: maximum bytes billed / dry-run / partition filter を必須。
- Athena: workgroupにスキャン上限・Parquet・partition・結果出力先を設定。
- `terraform apply`/`destroy`、`*delete*`、IAM・公開バケット変更は自動承認しない。人間確認必須。
- コスト発生の可能性がある判断は、実行前に必ずユーザーへ相談する。

## 確定事項
- クラウド: GCP・AWS並行フル構築。AWS DWHは Athena+Glue。
- データ: EC購買+GA4風行動ログ、数十万件規模。
- BI: Looker Studio(iframe) + Tableau Public。個人粒度データはPublicに出さない。
- ダッシュボード: Phase1(全体KPI/マーケ/コンテンツ)→Phase2(RFM・LTV/コホート/ファネル)→Phase3(クロスセル1本)→Phase4(オムニチャネルは発展編)。

## docs 索引
- `docs/dashboard_design.md` — ダッシュボード詳細設計(ページ別構成・分析軸)
- `docs/schema_design_base.md` — スキーマ基本方針(Phase1+2)
- `docs/tooling_recommendation.md` — MCP/skill/CLI選定と運用tips
