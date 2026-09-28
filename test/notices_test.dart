import 'dart:ui';

import 'package:anniv/features/notices/notices.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.parse('2026-10-01T12:00:00+09:00');

  List<Notice> parse(String raw,
          {String platform = 'ios', String version = '1.2.0'}) =>
      parseNotices(raw, platform: platform, version: version, now: now);

  test('keeps valid notices, newest first', () {
    final list = parse('''{"notices": [
      {"id": "a", "date": "2026-09-01", "title": "古い", "body": "x"},
      {"id": "b", "date": "2026-09-28", "title": {"ja": "新しい", "en": "New"}, "body": "y"}
    ]}''');
    expect(list.map((n) => n.id), ['b', 'a']);
    expect(list.first.title['en'], 'New');
    expect(list.last.title['ja'], '古い');
  });

  test('drops malformed entries and JSON', () {
    expect(parse('not json'), isEmpty);
    expect(parse('{"notices": {}}'), isEmpty);
    final list = parse('''{"notices": [
      {"date": "2026-09-01", "title": "no id"},
      {"id": "x", "title": "no date"},
      {"id": "y", "date": "2026-09-01"},
      {"id": "ok", "date": "2026-09-01", "title": "ok"}
    ]}''');
    expect(list.map((n) => n.id), ['ok']);
  });

  test('respects start and end', () {
    final list = parse('''{"notices": [
      {"id": "future", "date": "2026-09-01", "title": "t", "start": "2026-10-02T00:00:00+09:00"},
      {"id": "over", "date": "2026-09-01", "title": "t", "end": "2026-10-01T00:00:00+09:00"},
      {"id": "live", "date": "2026-09-01", "title": "t", "start": "2026-09-28T00:00:00+09:00", "end": "2026-10-27T00:00:00+09:00"}
    ]}''');
    expect(list.map((n) => n.id), ['live']);
  });

  test('respects platforms and version range', () {
    const raw = '''{"notices": [
      {"id": "android", "date": "2026-09-01", "title": "t", "platforms": ["android"]},
      {"id": "old", "date": "2026-09-01", "title": "t", "maxVersion": "1.1.9"},
      {"id": "new", "date": "2026-09-01", "title": "t", "minVersion": "1.10.0"},
      {"id": "mine", "date": "2026-09-01", "title": "t", "minVersion": "1.2.0", "maxVersion": "1.2.0"}
    ]}''';
    expect(parse(raw).map((n) => n.id), ['mine']);
    expect(parse(raw, platform: 'android').map((n) => n.id),
        containsAll(['android', 'mine']));
  });

  test('compareVersions is numeric', () {
    expect(compareVersions('1.10.0', '1.9.3'), 1);
    expect(compareVersions('1.2', '1.2.0'), 0);
    expect(compareVersions('1.2.0+9', '1.2.1'), -1);
  });

  test('pickText falls back ja → en → first', () {
    const texts = {'en': 'Hello', 'zh_Hant': '你好', 'ko': '안녕'};
    expect(pickText(texts, const Locale('ko')), '안녕');
    expect(
        pickText(texts,
            const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
        '你好');
    expect(pickText(texts, const Locale('th')), 'Hello');
    expect(pickText({'ja': 'こんにちは', 'en': 'Hi'}, const Locale('th')),
        'こんにちは');
  });
}
