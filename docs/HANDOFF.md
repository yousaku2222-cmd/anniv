# 引き継ぎメモ（2026-08-31 セッション）

このファイルは今回のセッションで進んだ作業のスナップショット。次回セッション
（このリポジトリを開いた別セッションでも可）はここから読めば状況が分かる。

## 0. 一言まとめ

Genspark のデザインモックをアプリ全体に反映 → iOS ウィジェット実装・実機(シミュレータ)確認
→ 収益化ゲート（リワード広告3種）追加 → Play クローズドテスト申請（審査中）
→ App Store 提出準備完了（Xcode Archive 待ち）。**コードは3箇所すべて同期済み**
（Windows `C:\dev\anniv` / Mac `~/line_talk_saver/anniv` / GitHub `main`、
最新コミット `80e78e5`、作業ツリークリーン）。

---

## 1. 今すぐ次にやること（優先順）

1. **Google Play クローズドテストの審査結果を確認** → 通ったら opt-in リンクを
   [募集キット Artifact](https://claude.ai/code/artifact/35b01a63-65ac-4e06-9967-2b588c3300b7) に反映して Discord 等で募集開始
   - ⚠ **今 Play にアップ済みの AAB（`852fc43` 相当・versionCode 2）には、この後に作った
     アイコン変更／リワード広告3種／バナー全画面化／日付1900年対応が入っていない。**
     テスターからのフィードバックが落ち着いたら、最新コミットで **新しい AAB を作って
     再アップロード**（versionCode を 3 に）。
2. **App Store 提出**（`docs/APP_STORE_SUBMIT.md` に手順一式）
   - Developer Portal で App ID×2 と App Group を登録
   - App Store Connect でアプリ作成、IAP `anniv_remove_ads` 作成
   - Mac で `open ios/Runner.xcworkspace` → **Product ▸ Archive**（GUI必須。
     `flutter build ipa` は Distribution 証明書が無くて失敗する）
   - Organizer ▸ Distribute App ▸ App Store Connect ▸ Upload
   - ストア掲載情報・プライバシーラベルを入力して審査へ
3. **AdMob リワード広告ユニットを実際に作成**して `lib/features/ads/ad_ids.dart`
   の `_androidRewarded` / `_iosRewarded` に反映（今は空欄＝Googleテストユニットで動作中）
4. **Play / App Store 両方の IAP `anniv_remove_ads`** を実際に作成・有効化（¥800想定）

---

## 2. 今回のセッションでやったこと（時系列）

### A. Genspark デザインモック全面反映
- `Annviデザイン/anniv-mockup-data.zip` を解析 → 朱色（`#E85D43`）ベースの
  デザイントークン層（`lib/core/theme/app_tokens.dart`, `anniv_widgets.dart`）
- ホーム／詳細／新規作成（5ステップウィザード化）／設定／オンボーディングを全面刷新
- アイコン・スプラッシュを新配色で再生成
- `google_fonts`（Zen Kaku Gothic New / Outfit）導入
- 関連コミット: `852fc43` `dbbe11d`

### B. iOS ウィジェット実装
- `AnnivWidget.swift`（TimelineProvider＋SwiftUI）、App Group `group.com.annivapp.anniv`
- Xcode で Widget Extension ターゲット追加、ビルドフェーズのサイクルを
  「Run Script/Thin Binary の "Based on dependency analysis" オフ」で解消
- **iOS Simulator（iPhone 17 Pro, iOS 26.5）で実際に描画確認済み**
  （「7日 / 推しのライブ / 9月7日 まで」を朱色配色で表示）
- 拡張のバージョンは `CURRENT_PROJECT_VERSION=2`/`MARKETING_VERSION=1.0.0` に固定
  （`$(FLUTTER_BUILD_*)` は拡張側では null になるため。**アプリのバージョンを
  上げたら `ios/Runner.xcodeproj/project.pbxproj` の Widget 側も手動で合わせること**）
- 関連コミット: `a55ba1c` `2df2db7` `03ce301`
- 手順書: `docs/WIDGET_SETUP.md`

### C. 日付・アイコンの改善
- 誕生日等が登録できるよう日付ピッカーを 1900年〜 に拡張（`0243b52`）
- **アイコン変更機能**を編集画面に追加。72個の厳選アイコン、シンプル/ライン切替
  （`lib/features/events/domain/event_icons.dart`）。iconCodePoint はすべて
  `Icons.*` const 経由で読むので release のアイコン tree-shake で消えない
  （`797903f` `9d89eb3` `279d3d2`）

### D. 収益化：リワード広告ゲート3種
| 機能 | ゲート方式 | 解放 |
|---|---|---|
| アイコン変更 | 1回視聴で**永続解放** | `AppSettings.iconChangeUnlocked`、`adRemoved`でも解放 |
| グループ追加 | **毎回**視聴必須 | 解放なし、`adRemoved`のみ免除 |
| 新規イベント登録（5個目以降） | 保存時に視聴必須 | 編集は対象外、`adRemoved`は免除 |

- 基盤: `RewardedAdService`（`lib/features/ads/data/rewarded_ad_service.dart`）、
  `AdIds.rewardedUnitId`（実ID未設定＝Googleテストユニットで動作）
- 全画面（詳細/編集/ウィザード/設定/ウィジェット設定）にバナー広告を常設
  （`BannerAdSlot`）。オンボーディングのみ除外
- **バグ→修正**: `BannerAdSlot` で `Container(alignment:)` を使うと
  `bottomNavigationBar` の無限高さ制約で画面が真っ白になった → `Align(heightFactor:1)`
  に変更して解消（`ca283fe`）。**同種のバグに注意**：`bottomNavigationBar` に
  積むウィジェットは高さを shrink-wrap すること
- 「広告除去 ¥800」を買うと上記3つのゲートは全部フリーになる（`adsEnabledProvider`
  / `iconChangeUnlockedProvider` で判定）
- 関連コミット: `17cb077` `528970b` `24bb32d` `ca283fe`

### E. Play クローズドテスト
- Play Console にアプリ作成済み（`app/4973978057574812686`、パッケージ
  `com.annivapp.anniv`）、コンテンツ申告10件すべて対応済み
- クローズドテスト（Alpha トラック）に AAB（versionCode 2）をアップロード→**審査提出済み**
- テスターグループ2つ運用: `anniv_test@googlegroups.com`（自前）＋
  `AndroidClosedJP@googlegroups.com`（相互テストコミュニティ）
- 募集キット Artifact: https://claude.ai/code/artifact/35b01a63-65ac-4e06-9967-2b588c3300b7
  （元ファイル `docs/tester-recruitment-kit.html`）

### F. App Store 提出準備
- `docs/APP_STORE_SUBMIT.md` に全手順（Developer Portal・ASC・IAP・プライバシー
  ラベル・審査備考・Archive手順）
- `ITSAppUsesNonExemptEncryption=false` 追加
- 6.9インチ(1320×2868)スクショ3枚 `docs/store-assets/appstore/`
  （ホーム／オンボーディング／設定。`adRemoved:true` で撮影しバナーなしのクリーンな画面）
- **未達**: `flutter build ipa` は Apple Distribution 証明書が無く失敗。
  Xcode の Archive フロー（GUI）で初回に証明書を自動生成する必要あり

---

## 3. リポジトリ・アカウント関連の場所

| 項目 | 値 |
|---|---|
| Windows リポジトリ | `C:\dev\anniv` |
| Mac リポジトリ | `~/line_talk_saver/anniv`（クローン先がネストしているだけで実害なし） |
| GitHub | `https://github.com/yousaku2222-cmd/anniv`、branch `main` |
| パッケージ名 / Bundle ID | `com.annivapp.anniv` |
| アップロード鍵（Android） | `C:\dev\anniv-keys\anniv-upload.jks`、alias `upload`、pw `Anniv50502!key` |
| Play Console アプリ | `app/4973978057574812686` |
| AdMob publisher | `pub-3818461038959537` |
| App Group (iOS) | `group.com.annivapp.anniv` |
| IAP 商品ID | `anniv_remove_ads`（Play/ASC とも未作成） |
| Mac SSH | `mizokamiyuusaku@192.168.1.13`（同一LAN、`~/.ssh/id_ed25519` 鍵登録済み。
  IP変動時は `mizokamiyuusakunoMacBook-Air.local` で再解決）→ 詳細は
  メモリ `reference_mac_ssh_ios_automation` |

## 4. ドキュメント索引（`docs/`）

- `STORE_SETUP.md` — AdMob/IAP/Play全般のセットアップ手順（バナー＋リワード両方）
- `WIDGET_SETUP.md` — iOS Widget Extension の作成手順（実施済み内容も追記済み）
- `APP_STORE_SUBMIT.md` — App Store 提出の手順一式
- `store-listing.md` — Play/App Store 掲載テキスト（日英）
- `store-assets/` — Play用素材、`store-assets/appstore/` — App Store用6.9インチスクショ
- `design/` — Genspark モックの元データ（spec, tokens, mockups画像）
- `tester-recruitment-kit.html` — クローズドテスト募集キット（Artifact化済み）

## 5. 既知の制約・ハマりどころ

- **Chrome Remote Desktop 越しのシミュレータ自動タップは信頼性が低い**。
  `cliclick` の座標計算はウィンドウ位置を毎回 python 経由の osascript で
  取り直せば当たることもあるが、外れることも多い。screenshot/terminate/launch/
  defaults write は100%安定して動く。込み入った画面遷移が要る作業は
  ユーザーに手動操作してもらい、結果をSSHでスクショ確認する分担が現実的
- ユーザープロファイル名の全角括弧（`優作（積算用）`）で Dart analysis server が
  壊れるため、Flutter/Dart プロジェクトは必ず ASCII パス（`C:\dev\...`）に置く
- iOS ウィジェット拡張のバージョンは Flutter の `$(FLUTTER_BUILD_*)` を継承できない
  ので手動同期が必要（§2-B参照）
