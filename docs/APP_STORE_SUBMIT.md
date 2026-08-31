# App Store 提出手順（Anniv v1.0.0）

Bundle ID: **`com.annivapp.anniv`** / Widget: `com.annivapp.anniv.AnnivWidget`
Apple ID: yousaku2222@gmail.com（有料 Apple Developer Program）

コード側は提出可能な状態。以下はアカウント作業＋Xcode 作業。

---

## 0. 事前チェック（コードは対応済み）

- [x] アプリアイコン（`ios/Runner/Assets.xcassets/AppIcon.appiconset/`、朱色キャンドル）
- [x] 起動画面（`flutter_native_splash`）
- [x] `NSUserTrackingUsageDescription`（ATT 文言）
- [x] `GADApplicationIdentifier` = `ca-app-pub-3818461038959537~2504402034`
- [x] `SKAdNetworkItems`（40件）
- [x] `ITSAppUsesNonExemptEncryption = false`（毎回の輸出コンプライアンス質問を省略）
- [x] iOS Deployment Target 15.0
- [x] AnnivWidgetExtension のバージョンは `CURRENT_PROJECT_VERSION=2` / `MARKETING_VERSION=1.0.0`
      （`pubspec.yaml` の `version` を上げたら project.pbxproj も手動で合わせる。→ `docs/WIDGET_SETUP.md`）
- [x] プライバシーポリシー: https://yousaku2222-cmd.github.io/anniv/privacy-policy.html

## 1. Apple Developer Portal

1. https://developer.apple.com/account → **Certificates, Identifiers & Profiles**
2. **Identifiers** に App ID を2つ登録（未登録なら）
   - `com.annivapp.anniv`（App）— Capabilities: **App Groups**, **In-App Purchase**
   - `com.annivapp.anniv.AnnivWidget`（App Extension）— Capabilities: **App Groups**
3. **App Groups** に `group.com.annivapp.anniv` を作成し、上記2つの App ID に紐付け
4. 署名は Xcode の **Automatically manage signing** に任せてよい（Distribution 証明書・
   Provisioning Profile を自動生成）

## 2. App Store Connect でアプリ作成

1. https://appstoreconnect.apple.com → マイ App → **＋ → 新規 App**
   - プラットフォーム: iOS
   - 名前: **Anniv**
   - プライマリ言語: 日本語
   - バンドル ID: `com.annivapp.anniv`
   - SKU: `anniv` など任意
   - ユーザーアクセス: フルアクセス
2. **App 情報**
   - サブタイトル: `誕生日・記念日カウントダウン`
   - カテゴリ: プライマリ **ライフスタイル**（セカンダリ 任意）
   - コンテンツ配信権: 該当なし
3. **価格および配信状況**: 無料 / 全地域（または日本のみ）

## 3. アプリ内課金（買い切り「広告を除去」）

**App 内課金 → ＋ → 非消耗型**
- 参照名: `広告を除去`
- 製品 ID: **`anniv_remove_ads`**（コードと完全一致・変更不可）
- 価格: ¥800（Tier 相当）
- 表示名（日本語）: `広告を除去`
- 説明: `バナー広告を非表示にし、アイコン変更・グループ追加・5個目以降の登録も広告なしで行えます。`
- 審査用スクリーンショット: 設定画面（「広告を除去する ¥800」の行）を添付
- ステータス: **提出準備完了**（アプリ本体のバージョンと一緒に審査へ）

## 4. バージョン情報（1.0.0）

- **スクリーンショット**: `docs/store-assets/appstore/` の 6.9インチ用（1320×2868）を最低2枚
  （6.9インチを入れれば他サイズは自動流用可）
- **プロモーションテキスト / 概要 / キーワード**: `docs/store-listing.md` の「App Store（日本語）」
- **サポート URL**: `https://yousaku2222-cmd.github.io/anniv/`（または問い合わせ先）
- **マーケティング URL**: 任意
- **著作権**: `2026 Yusaku Mizogami`
- **バージョン**: `1.0.0`

## 5. App のプライバシー（Nutrition Label）

「データの収集」→ **はい**（AdMob が収集）。以下を申告：

| データ種別 | 収集 | 目的 | ユーザーにリンク | トラッキング |
|---|---|---|---|---|
| **識別子 → デバイス ID** | はい | サードパーティ広告 | いいえ | **はい** |
| **位置情報 → おおよその位置情報** | はい | サードパーティ広告 | いいえ | はい |
| **使用状況データ → 製品操作** | はい | 分析 / サードパーティ広告 | いいえ | はい |
| **購入 → 購入履歴** | いいえ（IAP はローカル、開発者は取得しない） | — | — | — |

- 「トラッキングに使用」= はい（ATT プロンプトを表示）
- 記念日データ・グループ・設定は**端末内のみ**。開発者は取得しないので申告不要。

## 6. Xcode でアーカイブ＆アップロード

> ⚠ `flutter build ipa --release` は現状 **CodeSign failed** で失敗する。
> 手元には "Apple **Development**" 証明書しかなく、App Store 配布には
> "Apple **Distribution**" 証明書＋App Store プロビジョニングプロファイルが要る。
> これらは **Xcode の Archive フロー**が（アカウントにサインインしていれば）
> 自動生成するので、下記の GUI 手順で行う。

事前: **Xcode ▸ Settings ▸ Accounts** に Apple ID（yousaku2222@gmail.com）を追加。

1. `open ios/Runner.xcworkspace`
2. TARGETS ▸ Runner / AnnivWidgetExtension の Signing & Capabilities で
   **Automatically manage signing** ✔ / Team = 自分のチーム
3. スキーム **Runner** / 宛先 **Any iOS Device (arm64)**（シミュレータ不可）
4. **Product ▸ Archive**
   - 初回は「Apple Distribution 証明書を作成しますか？」に許可 → 自動作成
5. Organizer が開く → 対象アーカイブを選択 ▸ **Distribute App**
   ▸ **App Store Connect** ▸ **Upload**
   - AnnivWidgetExtension も自動で同梱・署名される
   - 「Upload your app's symbols」「Manage Version and Build Number」はデフォルトでOK
6. アップロード完了後、App Store Connect の「TestFlight」/「App Store ▸ ビルド」に
   反映（処理に数分〜30分、完了メールが来る）

（CLI で通したい場合は、上記 Archive を一度 GUI で通して Distribution 証明書と
プロファイルを作った後、`flutter build ipa --export-method app-store` が使える）

## 7. 審査へ提出

- バージョン画面でビルドを選択
- **App Review に関する情報**: 連絡先、`サインイン不要`（アカウント無し）
- **備考**:
  ```
  ・記念日カウントダウンアプリです。アカウント登録は不要で、データは端末内のみに保存されます。
  ・広告は Google AdMob（バナー＋リワード）。リワード広告はアイコン変更／グループ追加／
    5件目以降の登録で任意に視聴します。
  ・買い切り課金 anniv_remove_ads で全広告が無効化されます。
  ```
- **年齢制限**: コンテンツに応じて（暴力等なし → 4+ 相当。IARC は不要、Apple 独自質問に「なし」で回答）
- 「**手動でリリース**」推奨（審査通過後に自分のタイミングで公開）

## 8. TestFlight（任意・推奨）

審査前に内部テスターへ配布して実機確認できる。ビルドアップロード後、
TestFlight タブ → 内部テスターグループに追加 → 各自の TestFlight アプリで取得。
