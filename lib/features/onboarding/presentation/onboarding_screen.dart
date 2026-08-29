import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../settings/application/settings_providers.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(Icons.cake_outlined, size: 72, color: scheme.primary),
              const SizedBox(height: 24),
              Text('Anniv へようこそ',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                '誕生日や記念日を登録すると、当日と数日前にお知らせします。'
                'ホーム画面のウィジェットでも残り日数を確認できます。',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref.read(settingsProvider.notifier).completeOnboarding();
                  if (context.mounted) context.go('/');
                },
                child: const Text('はじめる'),
              ),
              const SizedBox(height: 8),
              Text(
                '通知の許可は最初の記念日を登録するときに確認します。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
