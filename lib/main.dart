import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'features/notifications/application/notification_providers.dart';
import 'features/notifications/data/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  final prefs = await SharedPreferences.getInstance();

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
      ],
      child: const AnnivApp(),
    ),
  );
}
