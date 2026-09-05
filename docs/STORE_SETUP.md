# ストア申請・収益化セットアップ

コード側（Sprint 5）は実装済みで、**Google のテスト広告**と「商品未登録」状態で
動作する。実際に配信・課金するには以下のアカウント作業が必要。

---

## 1. AdMob（広告）

1. https://admob.google.com でアカウント作成 → アプリを2つ登録（Android / iOS）
2. それぞれに **バナー広告ユニット** と **リワード広告ユニット** を作成
   （リワード＝アイコン変更の解放に使用。`_IconPickerSheet`）
3. 取得した ID を反映:
   | 場所 | 何を入れるか |
   |---|---|
   | `lib/features/ads/ad_ids.dart` `_androidBanner` / `_iosBanner` | バナーユニットID |
   | `lib/features/ads/ad_ids.dart` `_androidRewarded` / `_iosRewarded` | リワードユニットID（空ならGoogleテスト） |
   | `lib/features/ads/ad_ids.dart` `useTestAds` | `false` |
   | `android/app/src/main/AndroidManifest.xml` `com.google.android.gms.ads.APPLICATION_ID` | Android アプリID（`ca-app-pub-…~…`） |
   | `ios/Runner/Info.plist` `GADApplicationIdentifier` | iOS アプリID |
4. iOS の `SKAdNetworkItems` は `Info.plist` に主要40件を記載済み。メディエーションを
   追加する場合は各ネットワークのIDを追記
   https://developers.google.com/admob/ios/3p-skadnetworks
5. リリース前に**自分の端末をテストデバイス登録**して自己クリックを防ぐ
6. EEA/UK 配信する場合は AdMob 管理画面で **UMP（同意）メッセージ**を作成
   （コードは `AdService._requestConsent()` で対応済み）

## 2. 広告除去 IAP

商品ID: **`anniv_remove_ads`**（`lib/features/purchase/purchase_ids.dart`）

- **Google Play Console** → 収益化 → アプリ内アイテム → 「管理対象商品」を
  `anniv_remove_ads` で作成、価格設定（例: ¥300）、有効化
- **App Store Connect** → 内部購入 → 「非消耗型」を同じ商品IDで作成、価格設定、
  審査用スクショ添付
- 反映後、設定画面の「広告を非表示にする」に価格が表示され購入可能になる
  （それまでは灰色表示）

## 3. Google Play

1. Play Console でアプリ作成（パッケージ `com.annivapp.anniv`）
2. **データセーフティ**: 現状＝広告SDKが「広告ID・おおよその位置情報・端末ID」等を
   収集（AdMob 導入後）。IAP のみでアカウント無し。`docs/privacy-policy.html` を
   公開した URL を登録
3. **コンテンツのレーティング**: 記念日アプリ、暴力なし。全年齢想定
   （ただし子ども向けとしては配信しない ＝ ターゲットユーザー13歳以上）
4. リリース署名鍵を作成（`android/` に keystore、`key.properties`）
5. `flutter build appbundle --release` → **クローズドテスト**にアップロード
6. テスター: line_talk_saver と同じ Google グループを流用可
   （[[project_line_talk_saver_closed_testing]] 参照）。12名以上 or 公募20名

## 4. App Store（iOS）

1. Apple Developer Program 登録（有料）
2. App Store Connect でアプリ作成、Bundle ID `com.annivapp.anniv`
3. **プライバシー「ラベル」**: 「トラッキング」＝広告ID、「収集データ」＝ADID/使用状況
4. `NSUserTrackingUsageDescription`（Info.plist に設定済み）
5. Xcode でアーカイブ → TestFlight → 審査

## 5. ストア掲載素材

- [x] アプリアイコン（`assets/icon/`、`dart run flutter_launcher_icons` で生成）
- [ ] スクリーンショット（ホーム一覧 / 作成画面 / 詳細 / ウィジェット）各サイズ
- [ ] Google Play フィーチャーグラフィック 1024×500
- [ ] 説明文（短い説明 80字 / 詳細説明）
- [ ] プロモーション動画（任意）

## 6. リリース前チェック

- [x] `ad_ids.dart` の `useTestAds = false` ＋ 本番ユニットID（2026-09-05、バナー/リワードとも本番ID反映済み）
- [ ] AdMob アプリID（manifest / Info.plist）を本番に
- [ ] `lib/core/app_info.dart` `privacyPolicyUrl` を公開URLに
- [ ] `anniv_remove_ads` を両ストアで作成・有効化
- [ ] リリース署名
- [ ] `flutter build appbundle --release` / iOS アーカイブ
- [ ] 実機で本番広告が表示され、購入→広告消滅→復元 が通ることを確認
