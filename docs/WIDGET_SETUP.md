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

## iOS（✅ 実装済み・Simulator 動作確認済み 2026-08-31）

Xcode で Widget Extension ターゲットを追加し、iOS Simulator（iPhone 17 Pro /
iOS 26.5）で小ウィジェットの描画（`7 日 / 推しのライブ / 9月7日 まで`、朱色配色）と
App Group 経由のデータ連携を確認済み（コミット `2df2db7`）。以下は再現手順・注意点。

App Group id: **`group.com.annivapp.anniv`**（`AppHomeWidgetService.appGroupId` /
`ios/AnnivWidget/AnnivWidget.swift` / 両ターゲットの Capability で一致させる）。

### Flutter 側（済み）

- `main()` で `HomeWidget.setAppGroupId(AppHomeWidgetService.appGroupId)` を呼ぶ
- `AppHomeWidgetService.render()` は `anniv_empty/title/count/unit/caption` を保存し
  `updateWidget(iOSName: 'AnnivWidget')` を呼ぶ

### 事前用意済みのファイル（`ios/AnnivWidget/`, `ios/Runner/`）

| ファイル | 用途 |
|---|---|
| `ios/AnnivWidget/AnnivWidget.swift` | TimelineProvider＋SwiftUI ビュー（小/中サイズ、Anniv 配色、空状態対応） |
| `ios/AnnivWidget/AnnivWidgetBundle.swift` | `@main` の WidgetBundle |
| `ios/AnnivWidget/Info.plist` | 拡張の Info.plist |
| `ios/AnnivWidget/AnnivWidget.entitlements` | App Group（拡張側） |
| `ios/Runner/Runner.entitlements` | App Group（ホストアプリ側） |

### Xcode 手順

1. `open ios/Runner.xcworkspace`
2. **File ▸ New ▸ Target… ▸ Widget Extension**
   - Product Name: **`AnnivWidget`**
   - "Include Live Activity" / "Include Configuration Intent": **オフ**
   - Embed in Application: **Runner**
   - "Activate scheme?" は Cancel（Runner のまま）
3. Xcode が生成した `AnnivWidget/AnnivWidget.swift`・`AnnivWidgetBundle.swift`・
   `AnnivWidget.entitlements` の中身を、上の同名ファイルの内容で**置き換える**
   （生成された `AnnivWidgetControl.swift` / `*LiveActivity.swift` / `Assets.xcassets` は削除可）
4. **App Group を 2 つのターゲットに追加**
   - `Runner` を選択 ▸ Signing & Capabilities ▸ **+ Capability ▸ App Groups**
     ▸ `group.com.annivapp.anniv` を追加
   - `AnnivWidgetExtension` でも同じ手順で同じ group を追加
   - これで `ios/Runner/Runner.entitlements` が Runner に紐づく（既存ファイルを指すよう
     Build Settings の *Code Signing Entitlements* を `Runner/Runner.entitlements` に）
5. `AnnivWidget` ターゲットの **Deployment Target** を Runner と揃える（iOS 14 以上）
6. `AnnivWidget` ターゲットの Info.plist を `ios/AnnivWidget/Info.plist` に向ける
   （Build Settings ▸ *Info.plist File*）
7. `flutter build ios --config-only`（Flutter 3.47 は Swift Package Manager 方式。
   `ios/Podfile` は生成されず `pod install` は不要）
8. **ビルドフェーズのサイクル解消**（追加すると必ず出る）:
   Runner ▸ Build Phases ▸ **「Run Script」と「Thin Binary」の
   "Based on dependency analysis" のチェックを外す**
9. Runner を Run → ホーム画面長押し ▸ **＋** ▸ 「Anniv」▸ 「次の記念日」を配置
10. アプリで記念日を追加/編集 → ウィジェットが更新されることを確認
    （iOS はタイムライン更新が OS 任せ。すぐ反映されない場合はアプリを再度開く）

参考: `home_widget` iOS ガイド https://pub.dev/packages/home_widget#-ios

### 注意

- `AnnivWidget.swift` の `appGroupId` 定数と Capability の group id を**必ず一致**させる
- 無料の個人 Apple ID では App Group を作れないことがある（有料の Developer Program 必須）
- **バージョン固定**: AnnivWidgetExtension ターゲットは `CURRENT_PROJECT_VERSION = 2` /
  `MARKETING_VERSION = 1.0.0` を直書き、`Info.plist` は `$(CURRENT_PROJECT_VERSION)` /
  `$(MARKETING_VERSION)` を参照（`$(FLUTTER_BUILD_*)` は Runner の xcconfig 経由でしか
  効かず拡張では null になるため）。**`pubspec.yaml` の version を上げたら
  project.pbxproj の AnnivWidgetExtension 側の値も手動で合わせること**（不一致だと
  App Store 提出時に弾かれる）
- Xcode が `RunnerDebug.entitlements` / `AnnivWidgetExtensionDebug.entitlements` を
  自動生成する。事前用意した `Runner/Runner.entitlements` /
  `AnnivWidget/AnnivWidget.entitlements` と内容は同じ（App Group 1件）
