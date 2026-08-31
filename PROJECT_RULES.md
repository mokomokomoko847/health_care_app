# PROJECT_RULES.md

このファイルは、Codexが最初に確認するための入口です。

このプロジェクトの正式な仕様と開発ルールは `docs/` 配下の資料を参照すること。

## 最初に確認するファイル

1. アプリの目的、要件、Prototype 1 の範囲を確認する場合
   - `docs/product-requirements.md`
2. Codex の作業ルール、Human への確認事項、学習方針を確認する場合
   - `docs/development-rules.md`
3. docs 全体の入口を確認する場合
   - `docs/README.md`

## このファイルの役割

- Codexが最初に確認する入口である
- 正式な参照先が `docs/` 配下にあることを示す
- 実装前に、仕様と作業ルールの確認先を明確にする

## 運用ルール

- 仕様の正式な参照元は `docs/product-requirements.md`
- 開発ルールの正式な参照元は `docs/development-rules.md`
- `PROJECT_RULES.md` 単体を更新基準にせず、内容変更時は `docs/` 側を正式版として扱う
- Codexは作業前に必要に応じて `docs/` 配下の該当資料を確認すること

初心者が今回理解するとよいFlutter/Dartのポイント。

## テスト結果

Codex側で実行した確認・テストとその結果。

## Humanが確認すること

Flutterを起動したHumanが、
実際にどこを操作して何を確認すればよいか。

---

# 12. 次タスクへの移行

タスク完了後に勝手に次のタスクを実装しない。

Humanから

「OK」
「完了」
「次へ進んでください」

などの明確な承認を得てから次のタスクへ進むこと。
