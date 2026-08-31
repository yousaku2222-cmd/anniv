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

## iOS（Xcode 作業。Mac 必須）

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
7. `flutter build ios --config-only` → `pod install`（`ios/` で）
8. 実機 or シミュレータで Runner を Run → ホーム画面長押し ▸ **＋** ▸ 「Anniv」▸
   「次の記念日」を配置
9. アプリで記念日を追加/編集 → ウィジェットが更新されることを確認
   （iOS はタイムライン更新が OS 任せ。すぐ反映されない場合はアプリを再度開く）

参考: `home_widget` iOS ガイド https://pub.dev/packages/home_widget#-ios

### 注意

- `AnnivWidget.swift` の `appGroupId` 定数と Capability の group id を**必ず一致**させる
- 無料の個人 Apple ID では App Group を作れないことがある（有料の Developer Program 必須）
- App Store 提出時は AnnivWidget ターゲットにもバージョン/ビルド番号が要る
  （Info.plist で `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` を参照済み）
