---
name: guardrails
description: Define which operations require user confirmation and which technical decisions the agent may propose. Use this before changing scope, adding features, deleting data, adopting paid services, or making major implementation decisions.
---

- アプリの仕様を変更する場合は Human へ確認する
- 新しい機能を追加する場合は Human へ確認する
- Prototype 1 のスコープを変更する場合は Human へ確認する
- 有料サービスを使用する場合は Human へ確認する
- 既存データを削除する可能性がある場合は Human へ確認する
- 大きな設計変更を行う場合は Human へ確認する
- 要件が矛盾している場合は Human へ確認する
- AGENTS.md だけでは判断できない重要事項がある場合は Human へ確認する
- Flutter のファイル構成は提案してよい
- クラス構成は提案してよい
- Widget の選択は提案してよい
- 必要な Flutter package は提案してよい
- データベース候補は提案してよい
- 写真保存方式は提案してよい
- 状態管理方法は提案してよい
- コードの整理は提案してよい
- テスト方法は提案してよい
- カレンダー実装方法は提案してよい
- 大きな技術選定は採用理由を Human へ説明してから進める
- 採用した判断は該当する SKILL.md に理由つきで 1 行追記する
- ログインは実装しない
- AI 予測は実装しない
