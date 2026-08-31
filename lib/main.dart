import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'features/ads/application/ad_providers.dart';
import 'features/ads/data/ad_service.dart';
import 'features/notifications/application/notification_providers.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/widget/application/home_widget_providers.dart';
import 'features/widget/data/home_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  final prefs = await SharedPreferences.getInstance();

  // iOS: the widget extension reads its data from this shared App Group's
  // UserDefaults. Must match the group id on both Xcode targets and in
  // AnnivWidget.swift. No-op on Android.
  await HomeWidget.setAppGroupId(AppHomeWidgetService.appGroupId);

  // Local notifications are mobile-only; on desktop dev builds or if the plugin
  // isn't available, fall back to a no-op so the app still boots.
  NotificationService notifications = const NoopNotificationService();
  try {
    final service = FlutterLocalNotificationService();
    await service.init();
    notifications = service;
  } catch (e) {
    debugPrint('Anniv: notifications unavailable, running without them: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
        homeWidgetServiceProvider.overrideWithValue(const AppHomeWidgetService()),
        adServiceProvider.overrideWithValue(GoogleAdService()),
      ],
      child: const AnnivApp(),
    ),
  );
}
