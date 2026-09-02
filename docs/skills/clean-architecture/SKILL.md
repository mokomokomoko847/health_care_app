---
name: clean-architecture
description: Define layer responsibilities and dependency direction for code under lib. Use this before creating new classes, files, or directories.
---

- `lib` 配下の層と責務を守る
- 依存の向きは必ず内向きにする
- どこに何を置くかを先に決めてから新しいファイルを作る
- `models` にはデータの形とルールを置く
- `repositories` には保存と取得の窓口を置く
- `services` には DB・カメラなど外部との接点を置く
- `pages` には画面を置く
- `widgets` には画面をまたぐ部品を置く
- 現状は `models` / `pages` / `services` のみで `repositories` は無い
