# 楽ちん報告アプリ（仮）

診察時に医師へ生活状況を説明する手間を減らす健康ログアプリです。
血糖値・測定タイミング・メモ・食事写真を1件の記録として保存します。
Prototype 1 では、記録を保存し、カレンダーから日付ごとに見返します。

## スクリーンショット

画像の置き場所は `docs/images/` です。
`![記録入力画面](docs/images/record_input.png)`

## 技術スタック

- Flutter
- Dart
- sqflite
- image_picker

## ディレクトリ構成

- `lib/`
  - アプリのコードを置く
- `docs/`
  - 仕様と実装ルールのドキュメントを置く

## ドキュメント配置ルール表

この表をドキュメント配置ルールの正とする。

| 内容 | パス |
|---|---|
| AI 向け入口 | `AGENTS.md` |
| docs 配下の索引 | `docs/README.md` |
| 仕様の正 | `docs/product-requirements.md` |
| 禁止事項・確認が必要な操作 | `docs/skills/guardrails/SKILL.md` |
| Widget・状態管理・コメント方針 | `docs/skills/flutter/SKILL.md` |
| レイヤー分割・依存の向き | `docs/skills/clean-architecture/SKILL.md` |
| 画面遷移 | `docs/skills/app-flow/SKILL.md` |
| テスト方針 | `docs/skills/test/SKILL.md` |
| 画像 | `docs/images/` |

## ブランチ運用

- `main` は動くものだけを置く
- `develop` は開発の合流点にする
- `feature/<やること>` で実作業を進める

## AI で作業する場合

先に `AGENTS.md` を読む。
