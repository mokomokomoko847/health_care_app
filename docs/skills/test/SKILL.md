---
name: test
description: Define what to test and what not to test in Prototype 1. Use this before adding or changing tests.
---

- バリデーションの境界値は必ずテストする
- DB スキーマは必ずテストする
- 保存と読み出しは必ずテストする
- 見た目はテストしなくてよい
- パディングはテストしなくてよい
- Flutter のテストの実行コマンドは `flutter test` を使う

## Firebase のセキュリティ検証

- 採用理由：ユーザー指定の Authentication・Security Rules・App Check・テスト／監視の方針に従い、画面の操作制限を迂回したアクセスも検証する。
- セキュリティ要件の正は `../app-flow/requirements-definition/common.md` の「セキュリティ方針」とする。
- Cloud Firestore と Cloud Storage の Security Rules は Firebase Local Emulator Suite とルール用テストで検証する。`flutter test` だけで Security Rules の検証を完了した扱いにしない（[公式資料](https://firebase.google.com/docs/rules/unit-tests)）。
- メール確認済みの本人による許可された操作が成功することを確認する。
- 未認証・メール未確認・別ユーザーによる記録・写真・訂正履歴へのアクセスが拒否されることを確認する。
- 所有者の変更、型・必須項目・入力範囲に違反するデータ、訂正履歴単独の更新・削除が拒否されることを確認する。
- 記録全体の削除に伴う本人の写真・訂正履歴の削除は成功することを確認する。
- App Check はルール用テストとは別に検証する。強制適用を有効にした対象サービスで、正規の実機からのリクエストが成功し、有効な App Check トークンがないリクエストが拒否されることを確認する。
- 公開前に、本番アプリが App Check のデバッグ設定を使用していないことと、共通要件で指定した監視指標を確認できることを確認する。
