---
name: app-flow
description: Define screen flow and navigation rules for Prototype 1. Use this before adding or changing screens or navigation.
---

## 要件定義へのリンク

以下はこのファイルを基準とした相対パス。画面ごとの入力・表示要件はリンク先を正とし、このファイルでは画面遷移を定義する。

| 対象 | 要件定義の相対パス |
|---|---|
| 共通（目的・技術・対象範囲・完成条件） | [requirements-definition/common.md](requirements-definition/common.md) |
| ログイン・新規登録・メール確認待ち・パスワード再設定画面 | [requirements-definition/login.md](requirements-definition/login.md) |
| カレンダー画面 | [requirements-definition/calendar.md](requirements-definition/calendar.md) |
| 記録入力画面 | [requirements-definition/record-input.md](requirements-definition/record-input.md) |
| 日付ごとの詳細画面（画面内編集・削除・訂正履歴画面を含む） | [requirements-definition/daily-detail.md](requirements-definition/daily-detail.md) |

## 画面遷移のルール

- 画面遷移を Mermaid で 1 枚にまとめる
- 画面を増やすときは `requirements-definition/` に要件定義を置き、上の表と Mermaid 図を更新する。関連画面を既存の要件定義ファイル内で定義する場合も、表に対象画面を明記する
- 戻る動作の扱いを書く
- ログイン画面内で「新規登録」と「ログイン」を切り替える（別画面への遷移ではない）
- 認証済みかつメールアドレス確認済みの場合のみカレンダーへ遷移し、戻る操作でログイン画面へ戻さない。未確認の場合は確認待ち画面を表示する
- 新規記録の入力画面はカレンダーからのみ開き、保存成功後・入力を破棄して戻る場合はカレンダーへ戻る
- 詳細画面内で保存済み記録を編集・削除する。詳細画面から新規入力画面へは遷移しない
- 詳細画面から訂正履歴画面を開き、戻る操作で元の日付の詳細画面へ戻る
- カレンダーからログアウトした場合は認証後の画面履歴を解除し、ログイン画面へ戻る
- 再設定メールのリンクからアプリ内のパスワード再設定画面を開く。完了後はユーザーが手動でログイン画面へ戻る
- 日付ごとの詳細画面から戻る操作でカレンダーへ戻る
- カレンダー画面で端末の戻る操作をした場合、
  「アプリを終了しますか？」と確認を表示する。
- ユーザーが終了を選択した場合のみ、アプリを終了する。
- キャンセルした場合は、カレンダー画面に留まる。
- 入力画面の保存後・未保存時の動作、一覧の並び順、編集・削除可否は各画面の要件定義で管理する
- Firebase の採用理由: ユーザー指定により、ログインと記録保存を Firebase で扱う仕様へ変更する
- 写真保存の採用理由: ユーザー指定により写真も Firebase で管理するため、Cloud Storage for Firebase を使用する（課金設定の扱いは common.md を参照）
- 決めていないことは TODO: 要確認 と書く

## 図の読み方

上から「起動・認証」「ログイン後の画面移動」「新規記録の保存」「詳細画面内の編集・削除」の順に読む。
線の交差を避けるため、同じ画面を遷移先として再掲している。同名の箱は同じ画面を指し、新しい画面ではない。
エラー時の「画面に留まる」や詳細画面内の編集状態も、別画面への遷移ではなく、その場での表示更新を表す。

```mermaid
flowchart TB
    subgraph AUTH["1. 起動・認証"]
        A["アプリ起動"] --> S{"認証済み？"}
        S -->|いいえ| L["ログイン画面<br/>新規登録 / ログイン切り替え"]
        S -->|はい| V{"メール確認済み？"}
        V -->|はい| E["カレンダー画面"]
        V -->|いいえ| W["メール確認待ち画面"]
        L -->|ログイン| LA{"Firebase Authentication"}
        LA -->|成功| V
        LA -->|失敗| LE["ログイン画面に留まる・エラー表示"]
        L -->|新規登録| RA{"アカウント作成・認証"}
        RA -->|失敗| RE["新規登録モードに留まる・エラー表示"]
        RA -->|成功| MAIL{"確認メール送信"}
        MAIL -->|成功| W
        MAIL -->|失敗・エラー表示| W
        W -->|確認が完了しました| CHECK{"Firebase で確認状態を再取得"}
        CHECK -->|確認済み| E
        CHECK -->|未確認・取得失敗：エラー表示| W
        W -->|確認メールを再送する| RESEND{"確認メール再送"}
        RESEND -->|成功を通知 / 失敗を表示| W
        W -->|手動で戻る・認証解除| L
        L -->|パスワードを忘れた方| RM["再設定メールのアドレス入力画面"]
        RM -->|再設定メールを送信| SEND{"Firebase で再設定メール送信"}
        SEND -->|成功| SENT["送信完了を表示"]
        SEND -->|失敗・エラー表示| RM
        RM -->|通常の戻る操作| L
        SENT -->|手動で戻る| L
        SENT -->|メール内のリンクを開く| RESET["アプリ内のパスワード再設定画面"]
        RESET -->|コード検証・条件を満たすパスワードを設定| RESETCHECK{"Firebase で再設定"}
        RESETCHECK -->|成功| RESETDONE["完了を表示"]
        RESETCHECK -->|失敗・エラー表示| RESET
        RESETDONE -->|ユーザーが手動で戻る| L
        RESET -->|通常の戻る操作・未完了内容を破棄| L
    end

    subgraph NAV["2. ログイン後の画面移動"]
        E -->|記録入力ボタン| B["新規記録入力画面<br/>日時：日付ピッカー（未来日不可）→ 時刻ピッカー（未来時刻不可）<br/>写真：カメラ撮影 / 端末内写真を選択"]
        E -->|今日・過去の日付を選択| F["日付ごとの詳細画面"]
        E -->|未来の日付| FN["表示のみ・選択不可"]
        B -->|戻る| BU{"未保存の入力内容がある？"}
        BU -->|はい| BW["未保存確認"]
        BW -->|キャンセル| B
        BW -->|戻る・入力破棄| E
        BU -->|いいえ| E
        E -->|端末の戻る操作| EX["アプリ終了確認"]
        EX -->|キャンセル| E
        EX -->|終了| EXIT["アプリを終了"]
        E -->|ログアウト| OUT{"Firebase の認証解除"}
        OUT -->|成功・画面履歴と表示データを解除| L
        OUT -->|失敗・エラー表示| E
        F -->|戻る| E
        F -->|取得結果0件| EMPTY["この日の記録はありません<br/>追加ボタンなし"]
        EMPTY -->|戻る| E
        F -->|訂正履歴あり：訂正履歴ボタン| H["訂正履歴画面・閲覧専用"]
        H -->|戻る| F
    end

    subgraph ENTRY["3. 新規記録の保存"]
        B -->|記録を保存| C{"入力チェック・オンライン確認"}
        C -->|NG・エラー表示| B
        C -->|OK| D{"記録・写真を Firebase に保存"}
        D -->|すべて成功・入力破棄・カレンダー更新| E
        D -->|失敗・未確定・入力保持・日本語エラーダイアログ| B
    end

    subgraph DETAIL["4. 詳細画面内の編集・削除"]
        F -->|編集| EDIT["詳細画面内の編集状態<br/>保存済み内容を初期表示"]
        EDIT -->|戻る| UNSAVED{"未保存の変更がある？"}
        UNSAVED -->|いいえ| F
        UNSAVED -->|はい| WARN["未保存の編集内容の確認"]
        WARN -->|戻る・変更破棄| F
        WARN -->|キャンセル| EDIT
        EDIT -->|保存| VALID{"入力チェック・オンライン確認"}
        VALID -->|NG・エラー表示| EDIT
        VALID -->|OK| CORRECT{"血糖値・測定日時に変更あり？"}
        CORRECT -->|はい| CONFIRM["訂正確認"]
        CONFIRM -->|キャンセル| EDIT
        CONFIRM -->|訂正する| UPDATE{"記録・写真・必要な訂正履歴を更新"}
        CORRECT -->|いいえ| UPDATE
        UPDATE -->|失敗・未確定・入力保持・日本語エラーダイアログ| EDIT
        UPDATE -->|すべて成功| DATE{"測定日時の日付に変更あり？"}
        DATE -->|いいえ・一覧とカレンダー更新| F
        DATE -->|はい・変更前後のカレンダー更新| CHANGED["変更後の日付の詳細画面"]
        CHANGED -->|戻る| E
        F -->|削除| DELETECONFIRM["記録・写真・訂正履歴の削除確認"]
        DELETECONFIRM -->|キャンセル| F
        DELETECONFIRM -->|削除| DELETE{"オンライン確認・Firebase で削除"}
        DELETE -->|すべて成功・一覧とカレンダー更新| F
        DELETE -->|失敗・データ保持・日本語エラーダイアログ| F
    end

    AUTH ~~~ NAV
    NAV ~~~ ENTRY
    ENTRY ~~~ DETAIL
```
