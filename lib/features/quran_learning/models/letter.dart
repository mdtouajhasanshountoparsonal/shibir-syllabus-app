class ArabicLetter {
  final String id;
  final String arabic;
  final String nameBn;
  final String nameEn;
  final String pronunciationUrl;
  final List<String> forms; // initial, medial, final, isolated (order)
  final List<String> similarLetters;

  const ArabicLetter({
    required this.id,
    required this.arabic,
    required this.nameBn,
    required this.nameEn,
    required this.pronunciationUrl,
    required this.forms,
    required this.similarLetters,
  });

  factory ArabicLetter.fromJson(Map<String, dynamic> j) => ArabicLetter(
        id: j['id'] as String,
        arabic: j['arabic'] as String,
        nameBn: j['nameBn'] as String,
        nameEn: j['nameEn'] as String,
        pronunciationUrl: j['pronunciationUrl'] as String,
        forms: (j['forms'] as List<dynamic>).cast<String>(),
        similarLetters: (j['similarLetters'] as List<dynamic>? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabic': arabic,
        'nameBn': nameBn,
        'nameEn': nameEn,
        'pronunciationUrl': pronunciationUrl,
        'forms': forms,
        'similarLetters': similarLetters,
      };
}
