class DailyInspiration {
  final String id;
  final String content;
  final String? source;
  final String type; // 'Aya' or 'Hadith'
  final DateTime date;

  DailyInspiration({
    required this.id,
    required this.content,
    this.source,
    required this.type,
    required this.date,
  });

  factory DailyInspiration.fromFirestore(Map<String, dynamic> data, String id) {
    return DailyInspiration(
      id: id,
      content: data['content'] ?? '',
      source: data['source'],
      type: data['type'] ?? 'Aya',
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
