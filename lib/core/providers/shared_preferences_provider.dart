import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bound in `main()` via `ProviderScope(overrides: [...])` once
/// `SharedPreferences.getInstance()` has completed, so the rest of the app can
/// read it synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);
