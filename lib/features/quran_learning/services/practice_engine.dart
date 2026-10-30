import 'dart:math';

import '../models/letter.dart';
import '../models/level.dart';
import '../models/practice_question.dart';
import '../models/weak_word.dart';

/// Generates randomized practice questions from the letter/word data.
///
/// The lab exposes five question styles (A–E):
///  * `letter`  – recognise the letter by name
///  * `audio`   – hear the name and pick the matching letter
///  * `harakat` – identify the vowel mark on a letter
///  * `join`    – combine letter parts into a word
///  * `makhraj` – identify the articulation point / dot position
class PracticeEngine {
  PracticeEngine._();

  static final PracticeEngine instance = PracticeEngine._();

  final Random _rng = Random();

  /// Builds a mixed session for a set of [letters] using the full [pool] for
  /// distractor options. [focusIds] limits which letters are asked.
  List<PracticeQuestion> buildLetterSession(
    List<ArabicLetter> pool, {
    Set<String>? focusIds,
    int count = 10,
  }) {
    final focus = focusIds == null
        ? pool
        : pool.where((l) => focusIds.contains(l.id)).toList();
    final source = focus.isEmpty ? pool : focus;
    if (source.isEmpty) return const [];

    const types = ['letter', 'audio', 'harakat', 'makhraj'];
    final questions = <PracticeQuestion>[];

    for (var i = 0; i < count; i++) {
      final letter = source[_rng.nextInt(source.length)];
      final type = types[i % types.length];
      final q = _make(letter, pool, type, i);
      if (q != null) questions.add(q);
    }
    questions.shuffle(_rng);
    // E) Self-record voice-compare self check on one of the focus letters.
    final voiceLetter = source[_rng.nextInt(source.length)];
    questions.add(PracticeQuestion(
      id: 'voice_${voiceLetter.id}',
      type: 'voice',
      questionBn: 'এই হরফটি নিজে উচ্চারণ করো, তারপর নিজেকে যাচাই করো',
      promptArabic: voiceLetter.arabic,
      optionsAreArabic: false,
      correctAnswer: 'ঠিক বলেছি',
      options: const ['ঠিক বলেছি', 'আবার বলবো'],
      explanationBn: '${voiceLetter.arabic} (${voiceLetter.nameBn}) — '
          '${voiceLetter.makhraj}',
      letterId: voiceLetter.id,
    ));
    return questions;
  }

  /// Builds a join-the-word session from the practice word list.
  List<PracticeQuestion> buildWordSession(List<PracticeWord> words,
      {int count = 8}) {
    if (words.isEmpty) return const [];
    final questions = <PracticeQuestion>[];
    for (var i = 0; i < count; i++) {
      final word = words[i % words.length];
      final options = <String>{word.arabic};
      // distractors: other words' arabic (reversed look) + raw joined parts
      final others = words.where((w) => w.id != word.id).toList()..shuffle(_rng);
      for (final o in others) {
        if (options.length >= 4) break;
        options.add(o.arabic);
      }
      questions.add(PracticeQuestion(
        id: 'join_${word.id}_$i',
        type: 'join',
        questionBn: 'এই হরফগুলো জোড়া লাগালে কোন শব্দ হয়?',
        promptArabic: word.parts.join(' + '),
        optionsAreArabic: true,
        correctAnswer: word.arabic,
        options: options.toList()..shuffle(_rng),
        explanationBn: '${word.arabic} — ${word.nameBn}',
        letterId: '',
      ));
    }
    return questions;
  }

  /// Builds a revision session from weak words, re-using the join/word style.
  List<PracticeQuestion> buildRevisionSession(List<WeakWord> weak,
      List<PracticeWord> words) {
    final out = <PracticeQuestion>[];
    for (final w in weak) {
      if (w.splitParts.length >= 2) {
        final options = <String>{w.arabic};
        for (final o in words) {
          if (options.length >= 4) break;
          options.add(o.arabic);
        }
        out.add(PracticeQuestion(
          id: 'rev_${w.id}',
          type: w.kind,
          questionBn: 'ভুল হওয়া শব্দটি আবার পড়ুন — সঠিকটি বাছুন',
          promptArabic: w.splitParts.join(' + '),
          optionsAreArabic: true,
          correctAnswer: w.arabic,
          options: options.toList()..shuffle(_rng),
          explanationBn: w.reference,
          letterId: '',
        ));
      } else {
        out.add(PracticeQuestion(
          id: 'rev_${w.id}',
          type: w.kind,
          questionBn: 'ভুল হওয়া অংশটি আবার চিনুন',
          promptArabic: w.arabic,
          optionsAreArabic: false,
          correctAnswer: w.arabic,
          options: [w.arabic, w.reference, w.kindLabelBn, 'পুনরায় পড়ুন']
            ..shuffle(_rng),
          explanationBn: w.reference,
          letterId: '',
        ));
      }
    }
    return out;
  }

  PracticeQuestion? _make(
    ArabicLetter letter,
    List<ArabicLetter> pool,
    String type,
    int index,
  ) {
    switch (type) {
      case 'letter':
        return PracticeQuestion(
          id: 'letter_${letter.id}_$index',
          type: 'letter',
          questionBn: 'এই হরফটির নাম কী?',
          promptArabic: letter.arabic,
          optionsAreArabic: false,
          correctAnswer: letter.nameBn,
          options: _nameOptions(letter, pool),
          explanationBn: '${letter.arabic} = ${letter.nameBn}',
          letterId: letter.id,
        );
      case 'audio':
        return PracticeQuestion(
          id: 'audio_${letter.id}_$index',
          type: 'audio',
          questionBn: '“${letter.nameBn}” — কোন হরফটি?',
          promptArabic: '',
          optionsAreArabic: true,
          correctAnswer: letter.arabic,
          options: _arabicOptions(letter, pool),
          explanationBn: '${letter.nameBn} = ${letter.arabic}',
          letterId: letter.id,
        );
      case 'harakat':
        final marks = <String, String>{
          'fatha': 'ফাতহা (যবর)',
          'kasra': 'কাসরা (যের)',
          'damma': 'দাম্মা (পেশ)',
        };
        final keys = marks.keys.toList();
        final key = keys[_rng.nextInt(keys.length)];
        final shown = letter.harakat[key] ?? letter.arabic;
        return PracticeQuestion(
          id: 'harakat_${letter.id}_$index',
          type: 'harakat',
          questionBn: 'এই হরফের উপর কোন হরকত আছে?',
          promptArabic: shown,
          optionsAreArabic: false,
          correctAnswer: marks[key]!,
          options: marks.values.toList()..shuffle(_rng),
          explanationBn: '$shown — ${marks[key]}',
          letterId: letter.id,
        );
      case 'makhraj':
      default:
        final useDot = _rng.nextBool();
        return PracticeQuestion(
          id: 'makhraj_${letter.id}_$index',
          type: 'makhraj',
          questionBn: useDot
              ? '${letter.arabic} — বিন্দু কোথায়?'
              : '${letter.arabic} — উচ্চারণস্থান (মাখরাজ) কোনটি?',
          promptArabic: letter.arabic,
          optionsAreArabic: false,
          correctAnswer: useDot ? letter.dotInfo : letter.makhraj,
          options: _textOptions(
            useDot ? letter.dotInfo : letter.makhraj,
            pool.map((l) => useDot ? l.dotInfo : l.makhraj).toList(),
          ),
          explanationBn: '${letter.arabic} (${letter.nameBn}) — ${letter.makhraj}',
          letterId: letter.id,
        );
    }
  }

  List<String> _nameOptions(ArabicLetter correct, List<ArabicLetter> pool) {
    final opts = <String>{correct.nameBn};
    final others = [...pool]..shuffle(_rng);
    for (final o in others) {
      if (opts.length >= 4) break;
      if (o.similarLetters.contains(correct.id) ||
          correct.similarLetters.contains(o.id) ||
          opts.length < 3) {
        opts.add(o.nameBn);
      }
    }
    for (final o in others) {
      if (opts.length >= 4) break;
      opts.add(o.nameBn);
    }
    return opts.toList()..shuffle(_rng);
  }

  List<String> _arabicOptions(ArabicLetter correct, List<ArabicLetter> pool) {
    final opts = <String>{correct.arabic};
    final others = [...pool]..shuffle(_rng);
    for (final o in others) {
      if (opts.length >= 4) break;
      opts.add(o.arabic);
    }
    return opts.toList()..shuffle(_rng);
  }

  List<String> _textOptions(String correct, List<String> candidates) {
    final opts = <String>{correct};
    final others = candidates.toSet().toList()..shuffle(_rng);
    for (final o in others) {
      if (opts.length >= 4) break;
      opts.add(o);
    }
    return opts.toList()..shuffle(_rng);
  }
}
