import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/widget_snapshot.dart';

/// Platform boundary for the home-screen widget. The app pushes a
/// [WidgetSnapshot]; the native widget provider reads the same keys.
abstract class HomeWidgetService {
  Future<void> render(WidgetSnapshot snapshot);
}

class NoopHomeWidgetService implements HomeWidgetService {
  const NoopHomeWidgetService();

  @override
  Future<void> render(WidgetSnapshot snapshot) async {}
}

class AppHomeWidgetService implements HomeWidgetService {
  const AppHomeWidgetService();

  static const String androidProvider = 'AnnivWidgetProvider';
  static const String iOSWidget = 'AnnivWidget';

  /// iOS App Group shared between Runner and the AnnivWidget extension. Set once
  /// in `main()` via `HomeWidget.setAppGroupId`; the Swift widget reads
  /// `UserDefaults(suiteName:)` with this same id.
  static const String appGroupId = 'group.com.annivapp.anniv';

  @override
  Future<void> render(WidgetSnapshot snapshot) async {
    try {
      await HomeWidget.saveWidgetData<bool>('anniv_empty', snapshot.empty);
      await HomeWidget.saveWidgetData<String>('anniv_title', snapshot.title);
      await HomeWidget.saveWidgetData<String>('anniv_count', snapshot.count);
      await HomeWidget.saveWidgetData<String>('anniv_unit', snapshot.unit);
      await HomeWidget.saveWidgetData<String>('anniv_caption', snapshot.caption);
      await HomeWidget.saveWidgetData<int>(
          'anniv_icon_codepoint', snapshot.iconCodePoint);
      await HomeWidget.saveWidgetData<int>('anniv_color', snapshot.colorValue);
      await HomeWidget.updateWidget(
        androidName: androidProvider,
        iOSName: iOSWidget,
      );
    } catch (e) {
      debugPrint('Anniv: home widget update skipped: $e');
    }
  }
}
