import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shibir_syllabus_tracker/core/theme/app_colors.dart';
import 'package:shibir_syllabus_tracker/data/models/memorization.dart';
import 'package:shibir_syllabus_tracker/data/sources/content_parser.dart';
import 'package:shibir_syllabus_tracker/features/memorization/memorization_screen.dart';

void main() {
  test('MemorizationItem.fromJson parses per-ayah data', () {
    final item = MemorizationItem.fromJson({
      'id': 'memo_x',
      'title': 'সূরা আল-আসর',
      'ayahs': [
        {
          'number': 6177,
          'numberInSurah': 1,
          'arabic': 'وَٱلْعَصْرِ',
          'pronunciation': 'ওয়াল ‘আসর।',
          'meaning': 'কসম যুগের (সময়ের),',
          'audioUrl': 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6177.mp3',
        },
      ],
    });
    expect(item.hasAyahs, isTrue);
    expect(item.ayahs.length, 1);
    expect(item.ayahs.first.number, 6177);
    expect(item.ayahs.first.numberInSurah, 1);
    expect(item.ayahs.first.pronunciation, 'ওয়াল ‘আসর।');
  });

  test('bnNumber converts latin digits to Bangla', () {
    expect(bnNumber(0), '০');
    expect(bnNumber(103), '১০৩');
    expect(bnNumber(114), '১১৪');
  });

  test('MemoAyah.wordIndexAt maps elapsed ms to the active word', () {
    const ayah = MemoAyah(
      number: 6178,
      numberInSurah: 2,
      durationMs: 5800,
      words: [
        MemoWord(arabic: 'اِنَّ', startMs: 0, endMs: 1185),
        MemoWord(arabic: 'الْاِنْسَانَ', startMs: 1185, endMs: 3835),
        MemoWord(arabic: 'لَفِیْ', startMs: 3835, endMs: 4415),
        MemoWord(arabic: 'خُسْرٍ', startMs: 4415, endMs: 5480),
      ],
    );
    expect(ayah.wordIndexAt(0), 0);
    expect(ayah.wordIndexAt(500), 0);
    expect(ayah.wordIndexAt(1185), 1);
    expect(ayah.wordIndexAt(3999), 2);
    expect(ayah.wordIndexAt(5000), 3);
    expect(const MemoAyah(number: 1, numberInSurah: 1).wordIndexAt(100), -1);
  });

  test('bundled memorization.json carries per-ayah arrays', () {
    final raw = File('assets/content/memorization.json').readAsStringSync();
    final items = ContentParser.parseMemorization(raw);
    expect(items.length, 18);

    final asr = items.firstWhere((e) => e.id == 'memo_surah_103');
    expect(asr.hasAyahs, isTrue);
    expect(asr.ayahs.length, 3);
    expect(asr.ayahs.first.audioUrl,
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6177.mp3');
    expect(asr.ayahs.first.pronunciation, isNotEmpty);
    expect(asr.ayahs.first.meaning, isNotEmpty);
    expect(asr.ayahs.first.durationMs, greaterThan(0));
    expect(asr.ayahs.first.hasWords, isTrue);
    expect(asr.ayahs.first.words.first.arabic, isNotEmpty);
    expect(asr.ayahs[1].words.length, 4);
    expect(asr.ayahs[1].words.last.startMs,
        greaterThan(asr.ayahs[1].words.first.startMs));

    final dua = items.firstWhere((e) => e.id == 'memo_dua_knowledge');
    expect(dua.hasAyahs, isFalse);
    expect(dua.transliteration, isNotEmpty);

    // No legacy ayah markers linger anywhere.
    for (final item in items) {
      expect(item.arabic.contains('﴿'), isFalse);
      expect(item.arabic.contains('﴾'), isFalse);
    }
  });

  testWidgets('practice screen renders one card per ayah without markers',
      (tester) async {
    const item = MemorizationItem(
      id: 'memo_test',
      title: 'পরীক্ষা',
      reference: 'সূরা আল-আসর (১০৩)',
      ayahs: [
        MemoAyah(
          number: 6177,
          numberInSurah: 1,
          arabic: 'وَٱلْعَصْرِ',
          pronunciation: 'ওয়াল ‘আসর।',
          meaning: 'কসম যুগের (সময়ের),',
          audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6177.mp3',
        ),
        MemoAyah(
          number: 6178,
          numberInSurah: 2,
          arabic: 'إِنَّ ٱلْإِنسَٰنَ لَفِى خُسْرٍ',
          pronunciation: 'ইন্নাল ইনসা-না লাফী খুসর।',
          meaning: 'নিশ্চয়ই মানুষ ক্ষতির মধ্যে রয়েছে,',
          audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6178.mp3',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: MemorizationPracticeScreen(item: item)),
    );
    await tester.pump();

    expect(find.text('আয়াত ১'), findsOneWidget);
    expect(find.text('আয়াত ২'), findsOneWidget);
    expect(find.text('ওয়াল ‘আসর।'), findsOneWidget);
    expect(find.text('ইন্নাল ইনসা-না লাফী খুসর।'), findsOneWidget);
    expect(find.textContaining('﴿'), findsNothing);
    expect(find.textContaining('﴾'), findsNothing);

    // Two AnimatedContainers back the ayah cards; the first is active/highlighted
    // because playback starts on index 0.
    final containers = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    Color? borderColor(int i) => (containers[i].decoration as BoxDecoration)
        .border
        ?.top
        .color;
    expect(containers.length, 2);
    expect(borderColor(0), AppColors.accent);
    expect(borderColor(1), isNot(AppColors.accent));
  });

  testWidgets('practice screen renders ayah words as highlightable spans',
      (tester) async {
    const item = MemorizationItem(
      id: 'memo_words',
      title: 'পরীক্ষা',
      reference: 'সূরা আল-আসর (১০৩)',
      ayahs: [
        MemoAyah(
          number: 6177,
          numberInSurah: 1,
          durationMs: 1780,
          arabic: 'وَٱلْعَصْرِ',
          words: [
            MemoWord(arabic: 'وَ', bangla: 'শপথ', startMs: 0, endMs: 1715),
            MemoWord(arabic: 'ٱلْعَصْرِ', bangla: 'মহাকালের', startMs: 900, endMs: 1780),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: MemorizationPracticeScreen(item: item)),
    );
    await tester.pump();

    final rich = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((w) => w.text.toPlainText())
        .toList();
    expect(rich.any((t) => t.contains('ٱلْعَصْرِ')), isTrue);
  });
}
