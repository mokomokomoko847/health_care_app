# 楽ちん報告アプリ（仮）

診察時に医師へ生活状況を説明する手間を減らす健康ログアプリです。
血糖値・測定タイミング・メモ・食事写真を1件の記録として保存します。
Prototype 1 では、記録を保存し、カレンダーから日付ごとに見返します。

## メール・パスワード認証の実装

ログイン・新規登録・確認メール送信／再送・確認状態の再取得・ログアウトを
Firebase Authenticationへ接続しました。認証状態の復元中は読み込み画面を表示し、
未認証ならログイン、メール未確認なら確認待ち、確認済みならカレンダーへ進みます。
登録・認証中は重複送信とモード変更を防ぎ、失敗時は入力を保持して日本語で案内します。

- 認証窓口: `lib/services/auth_service.dart`
- 入力画面: `lib/pages/login_page.dart`
- 確認待ち: `lib/pages/email_verification_page.dart`
- 再設定メール送信・コード検証・新しいパスワードの設定: `lib/pages/password_reset_page.dart`
- 認証ガード: `lib/app_router.dart`。画面側の成功コールバックではなく認証状態で遷移します。
- 認証済み画面の記録は既存のサンプル表示／SQLite保存のままです。Firestoreへの移行・ユーザー別の記録保存は未実装です。

### メールリンクの追加設定（アプリ内での再設定に必要）

Firebaseの標準メールテンプレートのままでも、登録・確認メール・ログイン・再設定メール送信は動きます。
ただし標準の再設定リンクはFirebaseのブラウザー画面を開きます。
要件どおりアプリ内で新しいパスワードを設定するには、以下の設定が必要です。

1. 公開許可後に `firebase deploy --only hosting --project healthcare-da878` を実行する。
   `hosting/auth-action.html` はコードを固定のアプリURLへ渡す中継ページで、パスワードは入力しません。
2. Firebase Console → Authentication → Templates で、メールアドレス確認とパスワード再設定の
   アクションURLを `https://healthcare-da878.web.app/auth-action` に設定する。
   Firebaseから付与される `mode` と `oobCode` は中継ページがそのままアプリへ渡します。
3. Android / iOSのアプリをインストールした端末でメールリンクを開き、「アプリを開く」を押す。
   `rakuchinreport://auth/auth-action?mode=resetPassword&oobCode=...` をAndroid / iOSに登録しています。
4. アプリが再設定コードをFirebaseで検証した後だけ入力欄を表示します。
   8文字以上・英数字を含むパスワードを設定し、完了後に手動でログイン画面へ戻ります。

メール内のコードはログやスクリーンショットに載せないでください。
Hostingの公開とConsole設定が未完了の場合は、アプリ内再設定の導線は完成扱いにしません。
Firebaseの[メールアクションの仕様](https://firebase.google.com/docs/auth/custom-email-handler)と
[Flutterのユーザー管理API](https://firebase.google.com/docs/auth/flutter/manage-users)に沿って実装しています。

### 動作確認

```sh
fvm flutter test
fvm flutter analyze
fvm flutter run
```

実機では「新規登録 → 確認待ち → 受信メールのリンク → 確認が完了しました → カレンダー」、
再起動時のセッション復元、ログアウト、誤ったパスワード、通信失敗を確認してください。
HostingとConsole設定後は再設定メールからアプリ内でパスワードを変更し、新しいパスワードでログインしてください。
ユニット／WidgetテストではFirebase通信を差し替えており、本番でのメール到着や実機のリンク起動は別途確認が必要です。

## Firebase接続前の実装履歴

以下のログイン画面・Firebase導入状況は、接続前の段階を記録したものです。
現在の認証動作は上記「メール・パスワード認証の実装」を参照してください。

## 接続前のログイン画面（実装履歴）

起動時にFlutter製のログイン画面を表示します。ログイン／新規登録の切り替え、
入力チェック、パスワードの表示切り替えに対応しています。
切り替え時はメールアドレスを保持し、パスワードをクリアします。
添付HTMLのサンプル認証情報は初期入力せず、メールアドレスはプレースホルダーで表示します。

Firebase Authenticationへの接続処理は未実装です。現在のログインは入力内容にかかわらず
カレンダーへ進むモックです。新規登録・再設定メール送信は実行せず、未接続の案内を表示します。
既存の記録入力画面とSQLiteデータは保持しています。

## Firebase の導入状況（Android / iOS）

Firebase プロジェクト `healthcare-da878` に接続するための設定を導入しています。

- Android: `android/app/google-services.json`（`com.example.health_care_app`）
- iOS: `ios/Runner/GoogleService-Info.plist`（`com.example.healthCareApp`）。Runner のリソースに登録済みです。
- Flutter: `lib/firebase_options.dart` を使用し、`lib/main.dart` で Firebase の初期化完了後にアプリを起動します。
- パッケージ: `firebase_core` と `firebase_auth`。認証処理は次工程で接続します。
- Android の通信権限はリリースビルドでも使用できるように設定しています。

```sh
fvm flutter pub get
fvm flutter run
```

今回の設定対象は Android / iOS です。Web・macOS・Windows・Linux の Firebase 設定は含みません。
次工程では Firebase Console の Authentication でメール／パスワード認証の有効化を確認し、
ログイン・新規登録・パスワード再設定・ログアウトと認証状態による画面遷移を実装します。

## カレンダー画面のプレビュー（認証と接続しない単独表示）

添付HTMLをFlutterで再現したカレンダーを、次のコマンドで確認できます。

```sh
flutter run -t lib/main_calendar_preview.dart
```

月曜始まりの月表示、前月／翌月への切り替え、記録日の青色表示、今日の目印、
未来日の選択禁止に対応しています。年月と今日の判定は端末の日付を使用します。
プレビューには当月の10・12・14日（今日以前のみ）をサンプルの記録日として表示します。
実データの読み込み・保存は行いません。

今回は画面の実装までです。Firebase認証・記録の取得（読み込み中／取得失敗の表示を含む）・
日別詳細画面・記録入力画面への遷移・ログアウトは未接続です。
未接続の操作では案内を表示し、成功扱いにしません。
日付選択・記録入力・ログアウトには、後で接続できるコールバックを用意しています。
通常の`flutter run`では引き続きログイン画面が表示されます。

## スクリーンショット

画像の置き場所は `docs/images/` です。
`![記録入力画面](docs/images/record_input.png)`

## 技術スタック

- Flutter
- Dart
- Firebase（Core / Auth 接続済み。記録保存は sqflite）
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
