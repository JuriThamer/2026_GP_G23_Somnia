class Alarm {
  final bool smart;
  final String time;
  final List<int> days;
  final int window;
  final int repeats;

  const Alarm({
    this.smart = false,
    this.time = '',
    this.days = const [],
    this.window = 30,
    this.repeats = 1,
  });

  bool get isSet => time.isNotEmpty && days.isNotEmpty;

  DateTime? nextWake(DateTime now) {
    if (!isSet) return null;
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    for (var offset = 0; offset <= 1; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset, hour, minute);
      if (!day.isAfter(now)) continue;
      if (!days.contains(day.weekday - 1)) continue;
      if (day.difference(now) > const Duration(hours: 24)) continue;
      return day;
    }
    return null;
  }

  factory Alarm.fromMap(Map<String, dynamic> data) {
    return Alarm(
      smart: data['smart'] == true,
      time: data['time'] as String? ?? '',
      days: List<int>.from(data['days'] ?? const []),
      window: (data['window'] as num?)?.toInt() ?? 30,
      repeats: (data['repeats'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'smart': smart,
      'time': time,
      'days': days,
      'window': window,
      'repeats': repeats,
    };
  }

  Alarm copyWith({
    bool? smart,
    String? time,
    List<int>? days,
    int? window,
    int? repeats,
  }) {
    return Alarm(
      smart: smart ?? this.smart,
      time: time ?? this.time,
      days: days ?? this.days,
      window: window ?? this.window,
      repeats: repeats ?? this.repeats,
    );
  }
}
