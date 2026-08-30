# Anniv（アニヴ）

記念日・誕生日をカウントダウン通知するスマホアプリ。Flutter + Riverpod + go_router。

参考: TheDayBefore。設計プラン（機能分解・画面遷移・MVPスプリント）は
`C:\Users\優作（積算用）\Desktop\AIの作業場\記念日アプリ_実装計画.md`。

## 構成（feature-first）

```
lib/
  main.dart                      エントリ。SharedPreferences を読み ProviderScope に注入
  app.dart                       MaterialApp.router、テーマ、ロケール(ja)
  core/
    providers/                   sharedPreferencesProvider（main で override）
    router/app_router.dart       go_router。未オンボーディングなら /onboarding へ
    theme/app_theme.dart         Material 3、seed=キャンドルアンバー #C07D24
    time/day_time.dart           "HH:mm" 値オブジェクト
    time/clock.dart              Clock 抽象（テスト用 FixedClock）＋ todayProvider
  features/
    events/
      domain/     event.dart / countdown.dart（純粋な日付計算）/ event_templates.dart
      data/       event_repository.dart（抽象 ＋ SharedPrefs ＋ InMemory）
      application/event_providers.dart（EventsNotifier, visibleEventsProvider ほか）
      presentation/ home / event_edit / event_detail / event_presentation
    groups/       domain / data / application（EventGroup）
    settings/     domain / data / application / presentation（AppSettings）
    onboarding/   presentation
```

## 開発

```
flutter pub get
flutter analyze     # クリーン必須
flutter test        # domain（countdown / JSON）＋ 起動スモーク
flutter run
```

## Sprint 1 の範囲（済）

- ドメインモデル（Event / EventGroup / AppSettings）＋ JSON 永続化
- 純粋な日付計算（残り日数・経過日数・繰り返しの次回発生日・マイルストーン）
- ホーム一覧 / テンプレート作成 / 詳細 / 設定 / オンボーディング
- Riverpod プロバイダ構成、go_router ルーティング

## 次のスプリント

- 5   AdMob ＋ 広告除去 IAP ＋ ストア申請
- iOS ウィジェット Extension（Xcode、`docs/WIDGET_SETUP.md`）

## プライバシーポリシーの公開手順

1. `docs/privacy-policy.html` を GitHub Pages 等に公開する
   （例: このリポジトリを GitHub に push → Settings → Pages → `main /docs` → URL は
   `https://<user>.github.io/anniv/privacy-policy.html`）
2. 公開 URL を `lib/core/app_info.dart` の `privacyPolicyUrl` に設定
3. 同じ URL を App Store / Google Play のストア掲載情報に登録
4. 内容を編集するときは `docs/privacy-policy.md` を直し、HTML にも反映する

> 注意: このプロジェクトは ASCII パス（`C:\dev\...`）必須。ユーザープロファイル名の
> 全角括弧で Dart analysis server がクラッシュするため。
