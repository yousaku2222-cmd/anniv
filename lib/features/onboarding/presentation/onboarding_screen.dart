import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/anniv_widgets.dart';
import '../../events/application/event_providers.dart';
import '../../notifications/application/notification_providers.dart';
import '../../settings/application/settings_providers.dart';

/// Mirrors mock 01-splash: brand mark, thesis headline, a notification-permission
/// card, and three ways forward.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _busy = false;

  Future<void> _finish({bool askPermission = false, bool samples = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (askPermission) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
    if (samples) {
      await ref.read(eventsProvider.notifier).seedSamples();
    }
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: a.brandGradient,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: a.brand.withValues(alpha: 0.35),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.cake_outlined,
                      color: Colors.white, size: 56),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('大切な日まで、今日もあと何日。',
                    style: TextStyle(fontSize: 13, color: a.sub)),
              ),
              const SizedBox(height: 14),
              Text(
                '大切な日に、\n気づくアプリ。',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                  color: a.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '誕生日・記念日・試験までの残り日数を、ウィジェットと通知で毎日思い出させます。',
                style: TextStyle(fontSize: 13.5, height: 1.6, color: a.sub),
              ),
              const SizedBox(height: 28),
              AnnivCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnnivIconChip(
                        icon: Icons.notifications_outlined,
                        color: a.brand,
                        size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('通知を許可しますか？',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: a.ink)),
                          const SizedBox(height: 6),
                          Text(
                            '当日・7日・3日・1日前に、大切な日をお知らせします。いつでも設定で変更できます。',
                            style: TextStyle(
                                fontSize: 12.5, height: 1.55, color: a.sub),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _busy ? null : () => _finish(askPermission: true),
                child: const Text('通知を許可する'),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : () => _finish(),
                  child: const Text('あとで許可する'),
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: _busy ? null : () => _finish(samples: true),
                child: const Text('サンプルの記念日で試してみる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
