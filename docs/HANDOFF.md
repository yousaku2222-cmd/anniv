# 引き継ぎメモ（2026-08-31 セッション2）

このファイルは今回のセッションで進んだ作業のスナップショット。次回セッション
（このリポジトリを開いた別セッションでも可）はここから読めば状況が分かる。

## 0. 一言まとめ

**App Store 審査へ提出完了**（1.0.0 / ビルド2、Team YUSAKU MIZOGAMI）。
Developer PortalのApp ID×2・App Group、App Store ConnectのApp作成・IAP
（`anniv_remove_ads`）作成・バージョン情報・プライバシー申告、Xcodeでの
Archive＆Upload、審査用スクリーンショット（IAPレビュー用・iPad 13インチ用含む）
まで全て完了し、審査待ち（最大48時間）。Google Playクローズドテストは前回
セッションから審査提出済みのまま結果待ち。

---

## 1. 今すぐ次にやること（優先順）

1. **App Store審査結果を待つ**（最大48時間、メール通知が来る）。却下された場合は
   却下理由を確認して対応
2. **Google Play クローズドテストの審査結果を確認**（前回セッションから継続）
   → 通ったら [募集キット Artifact](https://claude.ai/code/artifact/35b01a63-65ac-4e06-9967-2b588c3300b7) の opt-in リンクを反映してDiscord等で募集開始
   - ⚠ 今Playにアップ済みのAAB（`852fc43`相当・versionCode 2）にはこの後の変更が
     未反映。フィードバックが落ち着いたら新しいAABを作って再アップロード（versionCode 3）
3. **AdMobリワード広告ユニットを実際に作成**して `lib/features/ads/ad_ids.dart`
   の `_androidRewarded` / `_iosRewarded` に反映（今は空欄＝Googleテストユニットで動作中）
4. iPadの審査用スクリーンショット（`docs/store-assets/appstore/ipad-01-home.png`）が
   空の状態（サンプルデータなし）のまま提出されている。審査通過後、余裕があれば
   サンプルイベントを入れた見栄えの良いスクショに差し替え可能（App本体の再提出は不要）

---

## 2. 今回のセッションでやったこと（時系列）

### A. Developer Portal 設定
- `com.annivapp.anniv`（App）に **App Groups** + **In-App Purchase** capability確認・付与
- `com.annivapp.anniv.AnnivWidget`（App Extension）に **App Groups** capability確認・付与
- `group.com.annivapp.anniv` App Groupを両App IDに紐付け確認

### B. App Store Connect
- アプリ「Anniv」作成（Bundle ID `com.annivapp.anniv`、SKU `anniv`、日本語）
- **App内課金** `anniv_remove_ads`（非消耗型・¥800）作成
  - 審査用スクリーンショットで**寸法エラーに遭遇** → 原因は「6.9インチではなく
    6.5インチサイズ（1284×2778等）が必要」かつ「アルファチャンネルなしのRGB」が
    必要だったこと（Web検索で判明、Apple公式ドキュメントには明記が薄い）。
    `docs/store-assets/appstore/iap-review-remove-ads.png` として保存済み
- バージョン情報（サブタイトル・プロモーションテキスト・概要・キーワード・
  サポートURL・著作権）入力、カテゴリ=ライフスタイル設定
- スクリーンショット3枚（6.9インチ、`01-home.png` `02-onboarding.png`
  `03-settings.png`）アップロード。**iPhoneタブはデフォルトで6.5インチ欄が
  表示される**ので、6.9インチに切り替える操作が必要だった
  （「メディアマネージャーですべてのサイズを表示」→ 6.9インチ欄へ）
- アプリのプライバシー（Nutrition Label）: デバイスID・位置情報・使用状況データを
  「サードパーティ広告」目的・トラッキング使用ありで申告し公開
- コンテンツ配信権: 「いいえ（サードパーティ製コンテンツを含まない）」を回答
- プライバシーポリシーURL未入力で審査提出がブロックされる不具合に遭遇 →
  `https://yousaku2222-cmd.github.io/anniv/privacy-policy.html` を入力して解消
- **iPad 13インチのスクリーンショットが必須**という要件に遭遇（Universal
  ビルドのため）→ iPad Pro 13-inch (M5) シミュレータで撮影
  （`docs/store-assets/appstore/ipad-01-home.png`、サンプルデータなしの空状態）

### C. Xcode Archive & Upload
- `Runner.xcworkspace` を開き、Signing & Capabilities で **Runner の
  「Signing (Release and Profile)」のTeamが未設定（None）だった不具合**に
  遭遇 → `YUSAKU MIZOGAMI` に設定して解消。AnnivWidgetExtensionは元々OK
- 実行先を Any iOS Device (arm64) に変更 → **Product ▸ Archive** 成功
  （Distribution証明書は確認ダイアログなしで自動生成された）
- Organizer ▸ Distribute App ▸ App Store Connect ▸ Upload 成功
  （Build 1.0.0 (2)、Uploaded to Apple確認）

### D. 審査提出
- ビルド処理完了後、App Reviewに関する情報（連絡先・サインイン不要・備考）を入力
- リリース方法、年齢制限を確認
- **「審査用に追加」→ 提出成功**（「2項目が提出されました」、ステータス
  「1.0 審査待ち」）

---

## 3. ハマりどころメモ（次回同種の作業をする時のために）

- **IAP審査用スクリーンショットは本体スクショと別基準**: 6.9インチではなく
  6.5インチサイズ（1242×2688 / 1284×2778等）、かつアルファチャンネルなしの
  RGB画像が必要。エラー文言は両方とも「寸法が正しくありません」で区別がつかない
- **iPhoneスクショタブはデフォルトで6.5インチ欄**が表示される。6.9インチで
  アップロードしたい場合は明示的に切り替えが必要
- **Universal（iPhone+iPad対応）ビルドはiPad用スクショも必須**。iPhone側だけ
  用意していても審査提出がブロックされる
- **XcodeのSigning設定はDebug/Release/Profileそれぞれ個別にTeamを設定する
  必要がある場合がある**（Automatically manage signingでも、Releaseだけ
  Noneのままになっていることがあった）
- **プライバシーポリシーURL**が空だと審査提出ボタンを押した時点でブロックされる
  （保存はできてしまうので気づきにくい）

## 4. リポジトリ・アカウント関連の場所

（前回から変更なし。詳細は git履歴のこのファイルの旧版、または
`docs/APP_STORE_SUBMIT.md` を参照）

| 項目 | 値 |
|---|---|
| Windows リポジトリ | `C:\dev\anniv` |
| Mac リポジトリ | `~/line_talk_saver/anniv` |
| GitHub | `https://github.com/yousaku2222-cmd/anniv`、branch `main` |
| パッケージ名 / Bundle ID | `com.annivapp.anniv` |
| Apple Developer Team | YUSAKU MIZOGAMI（Team ID `C6W29WNACK`） |
| Play Console アプリ | `app/4973978057574812686` |
| AdMob publisher | `pub-3818461038959537` |
| Mac SSH | メモリ `reference_mac_ssh_ios_automation` 参照 |
