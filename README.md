# 楽ちん報告アプリ（仮）

診察時に医師へ生活状況を説明する手間を減らす健康ログアプリです。
血糖値・測定タイミング・メモ・食事写真を1件の記録として保存します。
Prototype 1 では、記録を保存し、カレンダーから日付ごとに見返します。

## 現在のログイン画面

起動時にFlutter製のログイン画面を表示します。ログイン／新規登録の切り替え、
入力チェック、パスワードの表示切り替えに対応しています。
切り替え時はメールアドレスを保持し、パスワードをクリアします。
添付HTMLのサンプル認証情報は初期入力せず、メールアドレスはプレースホルダーで表示します。

Firebase Authenticationは未接続です。ログイン・登録・再設定メール送信は実行せず、
未接続の案内を表示します。認証後の画面には進めません。
既存の記録入力画面とSQLiteデータは保持しています。

## スクリーンショット

画像の置き場所は `docs/images/` です。
`![記録入力画面](docs/images/record_input.png)`

## 技術スタック

- Flutter
- Dart
- Firebase（移行予定。現在のアプリ実装は sqflite）
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
| AI 向けルール・docs 配下の索引 | `docs/AGENTS.md` |
| 仕様の正（共通・画面別要件） | `docs/skills/app-flow/requirements-definition/` |
| 禁止事項・確認が必要な操作 | `docs/skills/guardrails/SKILL.md` |
| Widget・状態管理・コメント方針 | `docs/skills/flutter/SKILL.md` |
| レイヤー分割・依存の向き | `docs/skills/clean-architecture/SKILL.md` |
| 画面遷移 | `docs/skills/app-flow/SKILL.md` |
| Google Stitch用の全画面デザイン指示書（要件の受け渡し用） | [docs/design.md](docs/design.md) |
| テスト方針 | `docs/skills/test/SKILL.md` |
| 画像 | `docs/images/` |

## ブランチ運用

- `main` は動くものだけを置く
- `develop` は開発の合流点にする
- `feature/<やること>` で実作業を進める

## AI で作業する場合

先に `docs/AGENTS.md` を読む。
ルートに `AGENTS.md` は置かないため、AI エージェントには `docs/AGENTS.md` を明示的に読み込ませる。
