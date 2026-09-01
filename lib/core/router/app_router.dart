import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/event_edit_screen.dart';
import '../../features/events/presentation/hidden_events_screen.dart';
import '../../features/events/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/application/settings_providers.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/widget/presentation/widget_setup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Rebuilds the router once, when onboarding completes.
  final onboardingDone =
      ref.watch(settingsProvider.select((s) => s.onboardingDone));

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!onboardingDone) return atOnboarding ? null : '/onboarding';
      if (atOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (_, _) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'hidden-events',
                builder: (_, _) => const HiddenEventsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'widget',
            builder: (_, _) => const WidgetSetupScreen(),
          ),
          GoRoute(
            path: 'event/new',
            builder: (_, _) => const EventEditScreen(),
          ),
          GoRoute(
            path: 'event/:id/edit',
            builder: (_, state) =>
                EventEditScreen(eventId: state.pathParameters['id']),
          ),
          GoRoute(
            path: 'event/:id',
            builder: (_, state) =>
                EventDetailScreen(eventId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
