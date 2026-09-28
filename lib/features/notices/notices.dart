// 運営からのお知らせ。
//
// GitHub Pages の `notices/<appId>.json` を起動時に読み、未読のお知らせを
// 起動時ダイアログと一覧画面で見せる。サーバー不要・再提出不要でお知らせを
// 出せるようにするためのもので、全アプリで同じファイルを使い回している
// （anniv / line_talk_saver / mbti_app / yabai_word / gungi）。
// 直すときは全アプリの同名ファイルを揃えること。
//
// JSON の書式は yousaku2222-cmd.github.io の notices/README.md を参照。
// 通信できないときは前回取得したものを出し、それも無ければ何も出さない。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _baseUrl = 'https://yousaku2222-cmd.github.io/notices/';
const _cacheKey = 'notices.cache';
const _readKey = 'notices.read';

/// One announcement, already filtered for this device.
class Notice {
  const Notice({
    required this.id,
    required this.date,
    required this.title,
    required this.body,
    this.url,
    this.urlLabel = const {},
    this.popup = true,
  });

  final String id;
  final DateTime date;

  /// Language code (`ja`, `en`, `zh_Hant`, ...) → text. See [pickText].
  final Map<String, String> title;
  final Map<String, String> body;
  final String? url;
  final Map<String, String> urlLabel;

  /// Whether to show it in the launch dialog (it's always in the list).
  final bool popup;
}

/// Parses the notices JSON and keeps the ones meant for this device right
/// now, newest first. Malformed entries are skipped; malformed JSON gives an
/// empty list.
@visibleForTesting
List<Notice> parseNotices(
  String raw, {
  required String platform,
  required String version,
  required DateTime now,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return const [];
  }
  final list = decoded is Map ? decoded['notices'] : null;
  if (list is! List) return const [];

  final result = <Notice>[];
  for (final e in list) {
    if (e is! Map) continue;
    final id = e['id'];
    final date = DateTime.tryParse('${e['date']}');
    final title = _texts(e['title']);
    final body = _texts(e['body']);
    if (id is! String || date == null || title.isEmpty) continue;

    final start = DateTime.tryParse('${e['start']}');
    final end = DateTime.tryParse('${e['end']}');
    if (start != null && now.isBefore(start)) continue;
    if (end != null && !now.isBefore(end)) continue;

    final platforms = e['platforms'];
    if (platforms is List && !platforms.contains(platform)) continue;

    final minVersion = e['minVersion'];
    final maxVersion = e['maxVersion'];
    if (minVersion is String && compareVersions(version, minVersion) < 0) {
      continue;
    }
    if (maxVersion is String && compareVersions(version, maxVersion) > 0) {
      continue;
    }

    final url = e['url'];
    result.add(Notice(
      id: id,
      date: date,
      title: title,
      body: body,
      url: url is String && url.isNotEmpty ? url : null,
      urlLabel: _texts(e['urlLabel']),
      popup: e['popup'] != false,
    ));
  }
  result.sort((a, b) => b.date.compareTo(a.date));
  return result;
}

/// A plain string counts as Japanese.
Map<String, String> _texts(Object? v) {
  if (v is String) return {'ja': v};
  if (v is Map) {
    return {
      for (final entry in v.entries)
        if (entry.value is String) '${entry.key}': entry.value as String,
    };
  }
  return const {};
}

/// Numeric compare of dotted versions: `1.10.0` > `1.9.3`.
@visibleForTesting
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  return 0;
}

/// Picks the text for [locale]: `zh_Hant` → `zh` → `ja` → `en` → anything.
@visibleForTesting
String pickText(Map<String, String> texts, Locale locale) {
  final script = locale.scriptCode;
  final keys = [
    if (script != null) '${locale.languageCode}_$script',
    locale.languageCode,
    'ja',
    'en',
  ];
  for (final k in keys) {
    final t = texts[k];
    if (t != null) return t;
  }
  return texts.values.isEmpty ? '' : texts.values.first;
}

class NoticeService {
  NoticeService._();

  static final NoticeService instance = NoticeService._();

  Future<void>? _loading;
  String? _language;
  List<Notice> _notices = const [];
  Set<String> _read = {};
  bool _popupShown = false;

  /// Number of notices not read yet; drives the unread dot.
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  List<Notice> get notices => _notices;

  bool isRead(Notice n) => _read.contains(n.id);

  /// Starts loading. Call once at startup; no need to await it.
  ///
  /// [language] fixes the display language for apps that only speak one
  /// (e.g. `'ja'`); leave it null to follow the app's current locale.
  Future<void> init(String appId, {String? language}) {
    _language = language;
    return _loading ??= _load(appId);
  }

  Locale _localeOf(BuildContext context) {
    final language = _language;
    return language != null
        ? Locale(language)
        : Localizations.localeOf(context);
  }

  Future<void> _load(String appId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _read = (prefs.getStringList(_readKey) ?? const []).toSet();
      final version = (await PackageInfo.fromPlatform()).version;
      final platform = Platform.isIOS ? 'ios' : 'android';

      void apply(String raw) {
        _notices = parseNotices(raw,
            platform: platform, version: version, now: DateTime.now());
        _updateUnread();
      }

      final cached = prefs.getString(_cacheKey);
      if (cached != null) apply(cached);

      final fresh = await _fetch(appId);
      if (fresh != null) {
        await prefs.setString(_cacheKey, fresh);
        apply(fresh);
      }
    } catch (e) {
      debugPrint('notices: load failed: $e');
    }
  }

  Future<String?> _fetch(String appId) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(Uri.parse('$_baseUrl$appId.json'));
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      return await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('notices: fetch failed: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  void _updateUnread() {
    unreadCount.value = _notices.where((n) => !_read.contains(n.id)).length;
  }

  Future<void> markRead(Iterable<String> ids) async {
    final before = _read.length;
    _read = {..._read, ...ids};
    _updateUnread();
    if (_read.length == before) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readKey, _read.toList());
    } catch (e) {
      debugPrint('notices: save failed: $e');
    }
  }

  /// Shows the newest unread popup notice once per launch, if any. Call from
  /// the first real screen after startup.
  Future<void> showPopupIfNeeded(BuildContext context) async {
    if (_popupShown) return;
    _popupShown = true;
    try {
      await (_loading ?? Future<void>.value())
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Too slow: skip it this launch rather than pop up mid-use.
      return;
    }
    if (!context.mounted) return;
    // Something else is on top (a what's-new sheet, a screen opened from a
    // share intent...): don't stack on it; it stays unread for next launch.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final unread =
        _notices.where((n) => n.popup && !_read.contains(n.id)).toList();
    if (unread.isEmpty) return;
    await showNoticeDialog(context, unread.first);
  }
}

/// Shows [notice] in a dialog and marks it read.
Future<void> showNoticeDialog(BuildContext context, Notice notice) {
  unawaited(NoticeService.instance.markRead([notice.id]));
  final locale = NoticeService.instance._localeOf(context);
  final url = notice.url;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(pickText(notice.title, locale)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(notice.date),
                style: Theme.of(dialogContext).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(pickText(notice.body, locale)),
          ],
        ),
      ),
      actions: [
        if (url != null)
          TextButton(
            onPressed: () {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
                  .catchError((_) => false);
            },
            child: Text(notice.urlLabel.isEmpty
                ? _ui(locale, 'open')
                : pickText(notice.urlLabel, locale)),
          ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(_ui(locale, 'close')),
        ),
      ],
    ),
  );
}

/// Opens the notices list; everything in it counts as read once seen.
Future<void> openNoticesScreen(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const NoticesScreen()),
  );
}

/// Title for the menu row that opens [NoticesScreen], in the device language.
String noticesMenuTitle(BuildContext context) =>
    _ui(NoticeService.instance._localeOf(context), 'title');

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  late final Set<String> _unreadAtOpen;

  @override
  void initState() {
    super.initState();
    final service = NoticeService.instance;
    // Remember what was new so the dots stay while this screen is open.
    _unreadAtOpen = {
      for (final n in service.notices)
        if (!service.isRead(n)) n.id,
    };
    service.markRead(service.notices.map((n) => n.id));
  }

  @override
  Widget build(BuildContext context) {
    final locale = NoticeService.instance._localeOf(context);
    final notices = NoticeService.instance.notices;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_ui(locale, 'title'))),
      body: notices.isEmpty
          ? Center(
              child: Text(_ui(locale, 'empty'),
                  style: theme.textTheme.bodyMedium),
            )
          : ListView.separated(
              itemCount: notices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = notices[i];
                return ListTile(
                  leading: _unreadAtOpen.contains(n.id)
                      ? const _Dot()
                      : const SizedBox(width: 8),
                  minLeadingWidth: 8,
                  title: Text(pickText(n.title, locale)),
                  subtitle: Text(_formatDate(n.date)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showNoticeDialog(context, n),
                );
              },
            ),
    );
  }
}

/// Wrap the first real screen (home, title...) with this to get the launch
/// dialog; see [NoticeService.showPopupIfNeeded].
class NoticePopupGate extends StatefulWidget {
  const NoticePopupGate({super.key, required this.child});

  final Widget child;

  @override
  State<NoticePopupGate> createState() => _NoticePopupGateState();
}

class _NoticePopupGateState extends State<NoticePopupGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NoticeService.instance.showPopupIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A red dot while there are unread notices; nothing otherwise.
class NoticeUnreadDot extends StatelessWidget {
  const NoticeUnreadDot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NoticeService.instance.unreadCount,
      builder: (_, count, _) =>
          count > 0 ? const _Dot() : const SizedBox.shrink(),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        shape: BoxShape.circle,
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/'
    '${d.day.toString().padLeft(2, '0')}';

const _uiTexts = <String, Map<String, String>>{
  'ja': {
    'title': 'お知らせ',
    'empty': 'お知らせはありません',
    'close': '閉じる',
    'open': '詳しく見る',
  },
  'en': {
    'title': 'News',
    'empty': 'No news yet',
    'close': 'Close',
    'open': 'Learn more',
  },
  'ko': {'title': '공지사항', 'empty': '공지사항이 없습니다', 'close': '닫기', 'open': '자세히 보기'},
  'zh': {'title': '公告', 'empty': '目前沒有公告', 'close': '關閉', 'open': '查看詳情'},
  'id': {
    'title': 'Pengumuman',
    'empty': 'Belum ada pengumuman',
    'close': 'Tutup',
    'open': 'Selengkapnya',
  },
  'th': {'title': 'ประกาศ', 'empty': 'ยังไม่มีประกาศ', 'close': 'ปิด', 'open': 'ดูรายละเอียด'},
};

String _ui(Locale locale, String key) =>
    (_uiTexts[locale.languageCode] ?? _uiTexts['en']!)[key]!;
