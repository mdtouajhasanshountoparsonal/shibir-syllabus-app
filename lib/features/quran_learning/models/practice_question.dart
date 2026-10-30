/// A single generated quiz question for the Letter Practice Lab.
class PracticeQuestion {
  final String id;
  final String type; // letter | harakat | join | makhraj | audio
  final String questionBn;
  final String promptArabic; // large Arabic shown as the prompt (may be empty)
  final bool optionsAreArabic; // whether options are Arabic (large) or Bangla
  final String correctAnswer;
  final List<String> options;
  final String explanationBn;
  final String letterId;

  const PracticeQuestion({
    required this.id,
    required this.type,
    required this.questionBn,
    required this.promptArabic,
    required this.optionsAreArabic,
    required this.correctAnswer,
    required this.options,
    required this.explanationBn,
    required this.letterId,
  });

  bool isCorrect(String answer) => answer == correctAnswer;

  factory PracticeQuestion.fromJson(Map<String, dynamic> j) => PracticeQuestion(
        id: j['id'] as String,
        type: j['type'] as String,
        questionBn: j['questionBn'] as String,
        promptArabic: (j['promptArabic'] ?? '') as String,
        optionsAreArabic: (j['optionsAreArabic'] ?? false) as bool,
        correctAnswer: j['correctAnswer'] as String,
        options: (j['options'] as List<dynamic>).cast<String>(),
        explanationBn: (j['explanationBn'] ?? '') as String,
        letterId: (j['letterId'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'questionBn': questionBn,
        'promptArabic': promptArabic,
        'optionsAreArabic': optionsAreArabic,
        'correctAnswer': correctAnswer,
        'options': options,
        'explanationBn': explanationBn,
        'letterId': letterId,
      };
}
