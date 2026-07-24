# ポートフォリオサイト 基本方針(Claude Code ドラフト)

Codexはこれをレビューし、詳細デザインシステムとページ内要素構成へ落とし込むこと。最終判断はClaude Code+ユーザー。

## 目的とターゲット
- フリーランスのデータエンジニア/アナリティクスエンジニア(小田航平)の案件受注が目的(→ [[user-profile-freelance]])。
- 閲覧者: 案件を出すクライアント、エージェント、採用担当。技術の深さと「事業に効くデータ活用」の両方を短時間で伝える。
- 一番の売り: 同一ECデータモデルを **BigQuery(warehouse)と S3/Athena(lakehouse)の2エンジンで実装し、dbtで共通KPI・品質テスト(141)を通して照合**した実証。加えて GA4準拠の行動ログ設計・BI(Looker Studio/Tableau)・(後日)自然言語分析AIエージェント。

## 技術スタック(確定)
- Next.js(App Router)+ TypeScript + Tailwind CSS、Vercel無料枠デプロイ。
- 作業ディレクトリ: `/Users/oda/portfolio-data-platform/web/`。
- ダッシュボードは Looker Studio / Tableau Public を iframe 埋め込み。
- 後追いで AIエージェント(Next.js APIルート + Claude tool use)を1機能として追加(→ 別途 docs のエージェント設計)。

## デザイン方針(キーカラーは確定、詳細はCodexで)
- トーン: Claude/Anthropic系の温かみのある暖色。ベージュ/クリームの背景に、テラコッタ/オレンジ/アンバーのアクセント、濃いインク色のテキスト。
- 信頼感と読みやすさ重視。派手すぎず、余白を活かす。データエンジニアの実直さと事業感覚の両立を表現。
- ライト基調(暖色背景)を主とし、必要に応じてダークセクションをアクセントに。
- 図(構成図・lineage)やコードは読みやすく。チャート/可視化を自作する場合はアクセシブルな配色を(dataviz原則)。

## 情報設計(ページ構成のたたき台)
1. **Home / Hero**: キャッチ(2エンジン×dbt×品質保証の一行サマリー)、主要指標(3エンジン一致・141テスト・売上¥124.5M規模のサンプル等)、CTA(実績を見る/連絡する)。
2. **About(経歴・強み)**: 職務要約、活かせるスキル(Python/SQL・BigQuery・GA4/GTM・Looker Studio/Tableau)、略歴、強み(事業部門とデータの橋渡し)。
3. **Architecture(構成)**: GCP版/AWS版の構成図、設計判断(warehouse vs lakehouse、Athena採用理由、方言ポータビリティ)、コスト設計・ガードレール。
4. **Data & Pipeline(データ基盤)**: サンプルデータ設計(EC購買+GA4行動ログ)、dbt lineage/レイヤー、データ品質テスト、トライエンジンparity(同一KPI)。
5. **Dashboards(BI)**: Looker Studio / Tableau Public 埋め込み。全体KPI/マーケ/コンテンツ/RFM/コホート/ファネルの見どころ解説。
6. **AI Analyst(後追い)**: 自然言語で分析を問い合わせるエージェント(text-to-SQL)。初期はComing soon枠でもよい。
7. **Contact**: 連絡先(メール等)、稼働条件、リンク(GitHub等)。

共通: グローバルナビ、フッター、レスポンシブ(モバイル対応)、日本語主・必要なら英語併記の余地。

## Codexへの依頼事項
1. 本基本方針をレビューし、不足・改善点を指摘。
2. 詳細デザインシステムの確定: 具体的なカラーパレット(暖色: 背景/アクセント/テキストのHEX、ライト/ダーク)、タイポグラフィ(和文/欧文フォント選定、見出し/本文スケール)、余白・角丸・影・コンポーネント方針(ボタン/カード/コード/図表)。Anthropic的な温かみを踏襲しつつ独自性を出す。
3. 各ページの要素構成(ワイヤーフレーム相当): セクション順、各セクションの見せる要素・コピーの骨子・図/数値の配置。
4. Next.js(App Router)+Tailwindでの実装構成案(ディレクトリ構成、共通コンポーネント、コンテンツの持ち方=MDX等)。
5. アウトプットは `/Users/oda/portfolio-data-platform/docs/site_design_detail.md` に提案形式でまとめる。実装(コード)は次段でClaude Codeがレビューの上Codexに依頼するので、この段では設計まで。
