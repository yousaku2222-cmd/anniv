import 'package:anniv/app.dart';
import 'package:anniv/core/providers/shared_preferences_provider.dart';
import 'package:anniv/features/events/presentation/home_screen.dart';
import 'package:anniv/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first launch shows onboarding, then home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const AnnivApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('まだ何も登録されていません'), findsOneWidget);
  });
}
