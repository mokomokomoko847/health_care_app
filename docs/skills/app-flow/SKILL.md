---
name: app-flow
description: Define screen flow and navigation rules for Prototype 1. Use this before adding or changing screens or navigation.
---

## 要件定義へのリンク

以下はこのファイルを基準とした相対パス。画面ごとの入力・表示要件はリンク先を正とし、このファイルでは画面遷移を定義する。

| 対象 | 要件定義の相対パス |
|---|---|
| 共通（目的・技術・対象範囲・完成条件） | [requirements-definition/common.md](requirements-definition/common.md) |
| ログイン画面 | [requirements-definition/login.md](requirements-definition/login.md) |
| カレンダー画面 | [requirements-definition/calendar.md](requirements-definition/calendar.md) |
| 記録入力画面 | [requirements-definition/record-input.md](requirements-definition/record-input.md) |
| 日付ごとの詳細画面 | [requirements-definition/daily-detail.md](requirements-definition/daily-detail.md) |

## 画面遷移のルール

- 画面遷移を Mermaid で 1 枚にまとめる
- 画面を増やすときは `requirements-definition/` に要件定義を置き、上の表と Mermaid 図を更新する
- 戻る動作の扱いを書く
- 決めていないことは `TODO: 要確認` と書く
- ログイン成功後はカレンダーへ遷移し、戻る操作でログイン画面へ戻さない
- カレンダーの記録入力ボタンから入力画面へ進み、戻る操作でカレンダーへ戻る
- 日付ごとの詳細画面から戻る操作でカレンダーへ戻る
- TODO: 要確認 — カレンダー画面での端末の戻る操作
- 入力画面の保存後・未保存時の動作、一覧の並び順、編集・削除可否は各画面の要件定義で管理する
- Firebase の採用理由: ユーザー指定により、ログインと記録保存を Firebase で扱う仕様へ変更する

```mermaid
flowchart TD
A[アプリ起動] --> S{認証状態}
S -->|未ログイン| L[ログイン画面]
S -->|認証状態を保持| T[起動時の遷移は TODO: 要確認]
L -->|メールアドレス・パスワード| LA{Firebase で認証}
LA -->|失敗・エラー表示| L
LA -->|成功| E[カレンダー画面]
E -->|記録入力ボタン| B[記録入力画面]
B -->|日時をタップ| B1[日付ピッカー・今日以前] --> B2[時刻ピッカー] --> B
B -->|カメラで撮影 / 写真を選択| B3[写真追加] --> B
B -->|記録を保存| C{入力チェック・未来日を拒否}
C -->|NG・エラー表示| B
C -->|OK| D[(Firebase に保存)]
D -->|保存失敗・入力保持・エラー表示| B
D -->|保存成功| P[保存後の遷移は TODO: 要確認]
B -->|戻る| E
E -->|記録がある日付をタップ| F[日付ごとの詳細画面]
E -->|記録がない日付をタップ| N[動作は TODO: 要確認]
F -->|取得結果が0件| F1[空状態の表示]
F1 -->|戻る| E
F -->|戻る| E
```
