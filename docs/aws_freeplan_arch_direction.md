# AWS Free Plan 制約と アーキテクチャ方向性(Claude Code ドラフト)

Codexはこれをレビューし、2026年の市場/求人トレンドに照らした構成見直しを詳細化すること。最終判断はClaude Code+ユーザー。

## 検証済み事実: AWS Free Plan(2025年7月改定)
- 新規アカウントは Free Plan / Paid Plan を選択。両者とも最大$200クレジット($100登録時+$100オンボーディングで獲得)。
- Free Planは「6か月 or クレジット枯渇」で終了しアカウント閉鎖。今回の目的(案件受託のため2〜3か月クライアントに提示できればよい)には期間制限は問題なし、とユーザー確認済み。
- Free Planは**リソース集約型の高額サービスを制限**。Redshift(Serverless含む)、SageMaker、Lightsail、GuardDuty等が制限/別トライアル扱い。Redshiftはfree accountでアクセス拒否(SubscriptionRequiredException)報告あり。
- always-free枠が30以上のサービスに存在(月次上限付き)。
- 料金・制限は変動するため、実装時に公式Free Tierページで再確認必須。

## ユーザーの意向
- 全工程が無料の範囲で収まるなら Free Plan で進めたい。
- ただし「コストのためにAthenaを選んだ(Redshiftを避けた)」等の妥協が、**無料のまま市場にマッチした構成に見直せるなら見直したい**。
- 期間制限(6か月)は問題なし(2〜3か月見せられればよい)。

## Claude Codeの方向性(たたき台)
1. **Athenaは妥協ではない**: S3+Glue+Athenaのサーバーレス・レイクハウスは、常時稼働型DWHから離れる近年のモダンデータスタックの潮流に合致。無料かつ市場性のある中核として維持する方針。
2. **Redshiftは無料の常時構成にできない**: 制限対象+コスト構造(最小8RPU/約$3時)のため、常時稼働の中核には不適。レジュメ価値のために入れるなら「クレジットで短時間起動→投入→クエリ/lineageスクショ→即停止」の使い捨てケーススタディに留める案。
3. **無料の範囲で市場性を底上げする候補**(採否と費用対効果をCodexに評価依頼):
   - Apache Iceberg等オープンテーブル形式(Glue/Athena対応、モダンレイクハウスの訴求)
   - Terraform によるIaC(GCP/AWS両方、再現性の訴求)
   - dbt によるCore→Mart変換(lineage/テスト/ドキュメント、アナリティクスエンジニアリング訴求)
   - サーバーレスETLオーケストレーション(Step Functions/EventBridge、Lambda中心。常時稼働computeやMWAA等の高額オーケストレータは避ける)
   - データ品質テスト(dbt test / Great Expectations 等)
   - CI/CD(GitHub Actions で lint/plan/test)

## Codexへの依頼事項
1. 上記方向性をレビューし、Free Plan(無料)の範囲で成立するか、制限に抵触する要素がないかを精査。抵触しうる要素は明示。
2. 2026年のデータエンジニア/アナリティクスエンジニア/BIエンジニア求人トレンドに照らし、現行のGCP(GCS/Cloud Functions or Cloud Run/BigQuery/Looker Studio)+AWS(S3/Glue/Athena/Lambda)構成に対し、**無料で追加でき市場性を高める要素**を優先度付きで提案。過剰な複雑化(費用対効果の低いもの)は「非推奨」として理由付きで除外。
3. Redshiftを「使い捨てケーススタディ」として入れる案の是非と、$200クレジットでの安全な実施手順(起動時間・想定消費クレジット・停止/削除手順)を評価。
4. GCP側についても、無料枠内でトレンドに合った構成強化余地があれば提案(例: dbt, Dataform, Cloud Composer回避の是非など)。
5. 見直し後の推奨アーキテクチャ(GCP版/AWS版それぞれ)を図示できるレベルで整理。

アウトプットは `/Users/oda/portfolio-data-platform/docs/architecture_review_market_fit.md` に提案形式でまとめること。断定せず、費用対効果と無料枠適合性を軸に。
