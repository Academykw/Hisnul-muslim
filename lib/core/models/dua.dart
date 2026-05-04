class Dua {
  final int reference;
  final String? title;
  final String? arabic;
  final String? translation;
  final String? transliteration;
  final String? bookReference;
  final String? group;
  bool isFav;

  Dua({
    required this.reference,
    this.title,
    this.arabic,
    this.translation,
    this.transliteration,
    this.bookReference,
    this.group,
    this.isFav = false,
  });

  // For dua group list items
  factory Dua.fromGroupCursor(Map<String, dynamic> map) {
    return Dua(
      reference: map['_id'] as int,
      title: map['en_title'] as String?,
      isFav: (map['fav_count'] as int? ?? 0) > 0,
    );
  }

  // For dua detail items
  factory Dua.fromDetailCursor(Map<String, dynamic> map) {
    return Dua(
      reference: map['_id'] as int,
      isFav: (map['fav'] as int? ?? 0) == 1,
      arabic: map['ar_dua'] as String?,
      translation: map['en_translation'] as String?,
      transliteration: map['en_transliteration'] as String?,
      bookReference: map['en_reference'] as String?,
    );
  }

  Dua copyWith({bool? isFav}) {
    return Dua(
      reference: reference,
      title: title,
      arabic: arabic,
      translation: translation,
      transliteration: transliteration,
      bookReference: bookReference,
      group: group,
      isFav: isFav ?? this.isFav,
    );
  }
}
