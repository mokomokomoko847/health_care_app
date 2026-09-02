# AGENTS.md

このプロジェクトで作業するAIエージェント共通のルールです。
各ドキュメントはファイル名ではなくパスで指定しています。記載のパスを直接開いてください。

## プロジェクト概要

楽ちん報告アプリ（仮）。診察時に医師へ生活状況を説明する手間を減らす健康ログアプリ。
血糖値・測定タイミング・メモ・食事写真を1件の記録として保存し、カレンダーから日付ごとに見返す。
現在はPrototype 1（MVP）。ログイン・AI予測は実装しない。

## 技術スタック

- Flutter / Dart
- ローカルDB: sqflite
- 写真取得: image_picker
- 状態管理: setState のみ（Prototype 1）

## ドキュメントの場所

| 内容 | パス |
|---|---|
| 仕様の正（何を作るか） | `docs/product-requirements.md` |
| docs 配下の索引 | `docs/README.md` |
| レイヤー分割・依存の向き | `docs/skills/clean-architecture/SKILL.md` |
| Widget・状態管理・コメント方針 | `docs/skills/flutter/SKILL.md` |
| 画面遷移 | `docs/skills/app-flow/SKILL.md` |
| テスト方針 | `docs/skills/test/SKILL.md` |
| 禁止事項・確認が必要な操作 | `docs/skills/guardrails/SKILL.md` |
| ドキュメント配置ルールの正 | `README.md` |

## 最上位ルール

- `main` / `develop` で直接作業しない。必ず `feature/<やること>` を切る
- 変更は Pull Request にする。ユーザーのレビューなしにマージしない
- 1つの関心事 = 1つの置き場所。同じ内容を2箇所に書かない
- skill の内容と実装がずれる場合は、skill を変更する前にユーザーへ確認する
- 既存ファイルを要約したり情報を削ったりしない

## 作業ルール

1. 画面・フォーム・一覧・ナビゲーション・スタイルを変更する前に `docs/skills/app-flow/SKILL.md` と `docs/skills/flutter/SKILL.md` を確認する
2. 新しいクラス・ファイル・ディレクトリを作る前に `docs/skills/clean-architecture/SKILL.md` を確認する
3. 血糖値・日時・メモ・写真の入力仕様や上限値を変更する前に `docs/product-requirements.md` を確認する
4. 画面遷移を追加・変更する前に `docs/skills/app-flow/SKILL.md` を確認し、Mermaid 図も更新する
5. テストを追加・変更する前に `docs/skills/test/SKILL.md` を確認する
6. 仕様変更・機能追加・データ削除・有料サービス導入の前に `docs/skills/guardrails/SKILL.md` を確認する
7. 新しい md を作る前に `README.md` のドキュメント配置ルール表を確認する

## タスクの進め方

1. 次に実行するタスクを確認する
2. 実装内容を簡潔に説明し、ユーザーの許可を得る
3. そのタスクだけ実装する
4. テストを行う
5. 完了報告をする（下の形式）
6. ユーザーの動作確認と OK を待つ。OK が出るまで次のタスクへ進まない

## 完了報告の形式

- 実装したこと
- 変更したファイル一覧
- コードのポイント（初心者が理解するとよい Flutter/Dart のポイント）
- テスト結果
- ユーザーが確認すること（どこを操作して何を見ればよいか）
