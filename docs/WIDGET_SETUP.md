# ホーム画面ウィジェット セットアップ

Flutter 側（`lib/features/widget/`）は実装済み。`AppHomeWidgetService` が
次の記念日を `home_widget` 経由でネイティブに渡し、`homeWidgetSyncProvider` が
イベント・日付変更のたびに更新する。渡すキー:

| キー | 例 |
|---|---|
| `anniv_empty` | `false` |
| `anniv_title` | `母の誕生日` |
| `anniv_count` | `12` / `当日` |
| `anniv_unit`  | `日` / `""` |
| `anniv_caption` | `9月3日 まで` |

## Android（実装済み・要実機確認）

追加済みファイル:

- `android/app/src/main/kotlin/com/annivapp/anniv/AnnivWidgetProvider.kt`
- `android/app/src/main/res/layout/anniv_widget.xml`
- `android/app/src/main/res/drawable/anniv_widget_background.xml`
- `android/app/src/main/res/xml/anniv_widget_info.xml`
- `android/app/src/main/res/values/strings.xml`
- `AndroidManifest.xml` に `<receiver android:name=".AnnivWidgetProvider">`

確認手順:

```
flutter run                     # 端末にインストール
# ホーム画面長押し → ウィジェット → Anniv → 「次の記念日までの残り日数」を配置
# アプリで記念日を追加/編集 → ウィジェットの数字が変わることを確認
```

未対応（v2 以降）: ダークテーマ対応の背景、複数サイズ、タップで該当イベント詳細へ。

## iOS（手動作業が必要）

iOS ウィジェットは Xcode で Widget Extension ターゲットを追加しないと動かない。
CLI からは生成できないため、以下を Xcode で行う:

1. `ios/Runner.xcworkspace` を開く
2. File > New > Target… > **Widget Extension**（名前 `AnnivWidget`、"Include Live Activity" はオフ）
3. 生成された `AnnivWidget` ターゲットと `Runner` ターゲットの両方に
   **App Group**（例 `group.com.annivapp.anniv`）を追加
4. Flutter 側の初期化で App Group を指定:
   ```dart
   // AppHomeWidgetService の各呼び出しに appGroupId を渡すか、
   // HomeWidget.setAppGroupId('group.com.annivapp.anniv') を main() で一度呼ぶ
   ```
5. `AnnivWidget.swift` の `TimelineProvider` で
   `UserDefaults(suiteName: "group.com.annivapp.anniv")` から
   `anniv_title` / `anniv_count` / `anniv_unit` / `anniv_caption` / `anniv_empty` を読む
6. `home_widget` の iOS 実装ガイド:
   https://pub.dev/packages/home_widget#-ios

App Group を設定したら、`AppHomeWidgetService` に `appGroupId` を通す必要がある
（現状は未指定 = Android のみ動作）。
