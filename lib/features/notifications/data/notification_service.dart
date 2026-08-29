import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_plan.dart';

/// Platform boundary for scheduling reminders. The app talks only to this
/// interface, so tests use [NoopNotificationService] and the domain
/// ([NotificationPlanner]) stays pure.
abstract class NotificationService {
  Future<void> init();

  /// Ask the OS for permission. Returns true if granted (or already granted).
  Future<bool> requestPermission();

  /// Make the set of pending OS notifications equal [plan]: cancel anything not
  /// in it, schedule anything missing.
  Future<void> sync(List<ScheduledNotification> plan);

  Future<void> cancelAll();
}

class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> sync(List<ScheduledNotification> plan) async {}

  @override
  Future<void> cancelAll() async {}
}

class FlutterLocalNotificationService implements NotificationService {
  FlutterLocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channel = AndroidNotificationChannel(
    'anniv_reminders',
    'リマインダー',
    description: '記念日・誕生日のカウントダウン通知',
    importance: Importance.high,
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // Resolve the real device zone so reminders fire at the intended wall-clock
    // time (e.g. 09:00 local), correct across DST changes. Falls back to UTC.
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Anniv: could not resolve local timezone, using UTC: $e');
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
          alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<void> sync(List<ScheduledNotification> plan) async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    final wanted = {for (final n in plan) n.id: n};

    for (final p in pending) {
      if (!wanted.containsKey(p.id)) {
        await _plugin.cancel(id: p.id);
      }
    }
    final existingIds = pending.map((p) => p.id).toSet();
    for (final n in plan) {
      if (existingIds.contains(n.id)) continue;
      await _schedule(n);
    }
  }

  Future<void> _schedule(ScheduledNotification n) async {
    try {
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        scheduledDate: tz.TZDateTime.from(n.fireAt, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: n.eventId,
      );
    } catch (e) {
      debugPrint('Anniv: failed to schedule #${n.id}: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
