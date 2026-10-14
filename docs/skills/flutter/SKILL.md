---
name: flutter
description: Define Flutter implementation rules for widgets, state management, comments, and dependency additions. Use this before writing or changing Flutter UI code.
---

- Prototype 1 では状態管理は setState のみを使う
- 状態管理を setState のみにする理由は Flutter 学習のためにコードを必要以上に複雑にしないため
- 状態管理の見直し条件は：
- health_care_app では状態管理に setState のみを使用する。
- 複数画面で同じ状態を共有する必要が生じ、setState だけでは管理が複雑になった場合に状態管理方法を見直す。
- Widget は build を分割する
- コードは読みやすくして初心者にも追いやすい構造にする
- 変数名は分かりやすくする
- クラス名は分かりやすくする
- 重要な Flutter / Dart コードには何のための処理なのかが分かる日本語コメントを付ける
- 単純な括弧や明白な構文には機械的に 1 行ずつコメントしない
- Human から質問されたときは何をしているコードかを説明できる状態にする
- Human から質問されたときはなぜ必要なのかを説明できる状態にする
- Human から質問されたときは Flutter / Dart のどの仕組みを使っているのかを説明できる状態にする
- 依存追加は Human へ確認する
