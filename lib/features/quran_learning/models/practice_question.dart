class PracticeQuestion {
  final String id;
  final String type;
  final String questionBn;
  final String correctAnswer;
  final List<String> options;
  final String? hint;

  const PracticeQuestion({
    required this.id,
    required this.type,
    required this.questionBn,
    required this.correctAnswer,
    required this.options,
    this.hint,
  });

  factory PracticeQuestion.fromJson(Map<String, dynamic> j) => PracticeQuestion(
        id: j['id'] as String,
        type: j['type'] as String,
        questionBn: j['questionBn'] as String,
        correctAnswer: j['correctAnswer'] as String,
        options: (j['options'] as List<dynamic>).cast<String>(),
        hint: j['hint'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'questionBn': questionBn,
        'correctAnswer': correctAnswer,
        'options': options,
        'hint': hint,
      };
}
