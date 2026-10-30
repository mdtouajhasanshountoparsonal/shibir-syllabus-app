class ArabicLetter {
  final String id;
  final int order;
  final String arabic;
  final String nameBn;
  final String nameEn;
  final String pronunciationUrl;
  final String dotInfo;
  final String makhraj;
  final List<String> forms; // initial, medial, final, isolated
  final List<String> formLabels;
  final Map<String, String> harakat;
  final List<String> similarLetters;

  const ArabicLetter({
    required this.id,
    required this.order,
    required this.arabic,
    required this.nameBn,
    required this.nameEn,
    required this.pronunciationUrl,
    required this.dotInfo,
    required this.makhraj,
    required this.forms,
    required this.formLabels,
    required this.harakat,
    required this.similarLetters,
  });

  String get fatha => harakat['fatha'] ?? arabic;
  String get kasra => harakat['kasra'] ?? arabic;
  String get damma => harakat['damma'] ?? arabic;
  String get sukun => harakat['sukun'] ?? arabic;
  String get shadda => harakat['shadda'] ?? arabic;

  factory ArabicLetter.fromJson(Map<String, dynamic> j) => ArabicLetter(
        id: j['id'] as String,
        order: (j['order'] as num?)?.toInt() ?? 0,
        arabic: j['arabic'] as String,
        nameBn: j['nameBn'] as String,
        nameEn: j['nameEn'] as String,
        pronunciationUrl: (j['pronunciationUrl'] ?? '') as String,
        dotInfo: (j['dotInfo'] ?? '') as String,
        makhraj: (j['makhraj'] ?? '') as String,
        forms: (j['forms'] as List<dynamic>).cast<String>(),
        formLabels: ((j['formLabels'] as List<dynamic>?) ?? const [])
            .cast<String>(),
        harakat: (j['harakat'] is Map)
            ? (j['harakat'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              )
            : const {},
        similarLetters:
            ((j['similarLetters'] as List<dynamic>?) ?? const []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'order': order,
        'arabic': arabic,
        'nameBn': nameBn,
        'nameEn': nameEn,
        'pronunciationUrl': pronunciationUrl,
        'dotInfo': dotInfo,
        'makhraj': makhraj,
        'forms': forms,
        'formLabels': formLabels,
        'harakat': harakat,
        'similarLetters': similarLetters,
      };
}
