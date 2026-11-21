class TranquilTone {
  final String toneId;
  final String title;
  final String storagePath;
  final int durationMinutes;

  const TranquilTone({
    required this.toneId,
    required this.title,
    required this.storagePath,
    required this.durationMinutes,
  });

  factory TranquilTone.fromMap(String toneId, Map<String, dynamic> data) {
    return TranquilTone(
      toneId: toneId,
      title: data['title'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
