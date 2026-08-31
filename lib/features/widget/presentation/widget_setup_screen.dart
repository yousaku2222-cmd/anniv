import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/anniv_widgets.dart';
import '../../../core/time/clock.dart';
import '../../ads/presentation/banner_ad_widget.dart';
import '../../events/application/event_providers.dart';
import '../../events/domain/countdown.dart';
import '../../events/domain/event.dart';
import '../../events/domain/event_templates.dart';

/// Explains how to add the home-screen widget and previews it with the user's
/// own upcoming events. Mirrors mock 05-widget.
class WidgetSetupScreen extends ConsumerStatefulWidget {
  const WidgetSetupScreen({super.key});

  @override
  ConsumerState<WidgetSetupScreen> createState() => _WidgetSetupScreenState();
}

class _WidgetSetupScreenState extends ConsumerState<WidgetSetupScreen> {
  bool _medium = true;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    final today = ref.watch(todayProvider);
    final events = ref.watch(visibleEventsProvider);
    final rows = events.take(_medium ? 3 : 1).toList();

    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Text('ホーム画面ウィジェット',
            style: TextStyle(
                color: a.brand, fontSize: 16, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 8, AppSpacing.screenH, 40),
        children: [
          Text('ウィジェットを追加',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: a.ink)),
          const SizedBox(height: 8),
          Text(
            'ホーム画面で「あと何日」が一目でわかるように。複数のイベントもまとめて表示できます。',
            style: TextStyle(fontSize: 13, color: a.sub, height: 1.5),
          ),
          const SizedBox(height: 20),
          _Segment(
            medium: _medium,
            onChanged: (v) => setState(() => _medium = v),
          ),
          const SizedBox(height: 16),
          _WallpaperPreview(rows: rows, today: today, medium: _medium),
          const SizedBox(height: 20),
          const _Step(
            n: 1,
            title: 'ホーム画面を長押し',
            body: ' → 「＋」をタップ → 「Anniv」を選んで追加します。',
          ),
          const SizedBox(height: 12),
          const _Step(
            n: 2,
            title: '更新タイミング',
            body:
                ' — アプリを開いたとき・日付が変わったときに自動更新（v1 では次回起動時に反映）。',
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.medium, required this.onChanged});
  final bool medium;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: a.chipBg,
        borderRadius: BorderRadius.circular(AppRadius.seg),
      ),
      child: Row(
        children: [
          _seg(context, '中サイズ（4件）', medium, () => onChanged(true)),
          _seg(context, '小サイズ（1件）', !medium, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, String label, bool on, VoidCallback tap) {
    final a = context.anniv;
    return Expanded(
      child: GestureDetector(
        onTap: tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: on ? a.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.seg - 3),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: on ? a.ink : a.sub,
            ),
          ),
        ),
      ),
    );
  }
}

class _WallpaperPreview extends StatelessWidget {
  const _WallpaperPreview(
      {required this.rows, required this.today, required this.medium});
  final List<Event> rows;
  final DateTime today;
  final bool medium;

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final clock =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FB2E5), Color(0xFF3F6AB8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Text(
                  '${DateFormat('M月d日(E)', 'ja').format(today)}  $clock',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.wifi, color: Colors.white70, size: 15),
                const SizedBox(width: 4),
                const Icon(Icons.battery_full, color: Colors.white70, size: 15),
              ],
            ),
          ),
          if (rows.isEmpty)
            const _WidgetRowPlaceholder()
          else
            for (final e in rows) ...[
              _WidgetRow(event: e, today: today),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _WidgetRow extends StatelessWidget {
  const _WidgetRow({required this.event, required this.today});
  final Event event;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final left = Countdown.daysLeft(event, today);
    final color = event.displayColor;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AnnivIconChip(icon: event.displayIcon, color: color, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('M月d日(E)', 'ja')
                      .format(Countdown.nextOccurrence(event, today)),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            left == 0 ? '当日' : 'あと $left 日',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetRowPlaceholder extends StatelessWidget {
  const _WidgetRowPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'イベントを登録すると、ここに表示されます。',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.body});
  final int n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return AnnivCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: a.brandSoft, shape: BoxShape.circle),
            child: Text('$n',
                style: TextStyle(
                    color: a.brand, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                        fontWeight: FontWeight.w900, color: a.ink, fontSize: 14),
                  ),
                  TextSpan(
                    text: body,
                    style: TextStyle(color: a.sub, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
