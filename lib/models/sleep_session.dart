import 'package:cloud_firestore/cloud_firestore.dart';

class StageStat {
  final int minutes;
  final int percent;

  const StageStat({required this.minutes, required this.percent});

  factory StageStat.fromMap(Map<String, dynamic> data) {
    return StageStat(
      minutes: (data['minutes'] as num? ?? 0).toInt(),
      percent: (data['percent'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {'minutes': minutes, 'percent': percent};
}

class SleepSummary {
  final int inBedMinutes;
  final int totalSleepMinutes;
  final DateTime? sleepTime;
  final DateTime? wakeTime;
  final Map<String, StageStat> stages;
  final double? avgHeartRate;
  final double? avgSkinTemp;
  final double? stillnessPercent;

  const SleepSummary({
    required this.inBedMinutes,
    required this.totalSleepMinutes,
    this.sleepTime,
    this.wakeTime,
    this.stages = const {},
    this.avgHeartRate,
    this.avgSkinTemp,
    this.stillnessPercent,
  });

  factory SleepSummary.fromMap(Map<String, dynamic> data) {
    final rawStages = Map<String, dynamic>.from(data['stages'] ?? {});
    return SleepSummary(
      inBedMinutes: (data['inBedMinutes'] as num? ?? 0).toInt(),
      totalSleepMinutes: (data['totalSleepMinutes'] as num? ?? 0).toInt(),
      sleepTime: (data['sleepTime'] as Timestamp?)?.toDate(),
      wakeTime: (data['wakeTime'] as Timestamp?)?.toDate(),
      stages: rawStages.map(
        (key, value) =>
            MapEntry(key, StageStat.fromMap(Map<String, dynamic>.from(value))),
      ),
      avgHeartRate: (data['avgHeartRate'] as num?)?.toDouble(),
      avgSkinTemp: (data['avgSkinTemp'] as num?)?.toDouble(),
      stillnessPercent: (data['stillnessPercent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inBedMinutes': inBedMinutes,
      'totalSleepMinutes': totalSleepMinutes,
      'sleepTime': sleepTime == null ? null : Timestamp.fromDate(sleepTime!),
      'wakeTime': wakeTime == null ? null : Timestamp.fromDate(wakeTime!),
      'stages': stages.map((key, value) => MapEntry(key, value.toMap())),
      'avgHeartRate': avgHeartRate,
      'avgSkinTemp': avgSkinTemp,
      'stillnessPercent': stillnessPercent,
    };
  }
}

class RestReview {
  static const Map<String, String> sleepInertiaOptions = {
    'notAtAll': 'Not at all',
    'aLittle': 'A little',
    'aLot': 'A lot',
  };

  static const Map<String, String> toneReuseOptions = {
    'yes': 'Yes',
    'maybe': 'Maybe',
    'no': 'No',
  };

  static const Map<String, String> sleepFactorOptions = {
    'caffeineLate': 'Caffeine late',
    'screenUseInBed': 'Screen use in bed',
    'stress': 'Stress',
    'illness': 'Illness',
    'noise': 'Noise around me',
    'none': 'None',
  };

  final int? sleepiness;
  final String? sleepInertia;
  final int? toneRelaxing;
  final String? toneReuse;
  final List<String> sleepFactors;
  final DateTime? submittedAt;

  const RestReview({
    this.sleepiness,
    this.sleepInertia,
    this.toneRelaxing,
    this.toneReuse,
    this.sleepFactors = const [],
    this.submittedAt,
  });

  static List<int> questionsFor({required bool hasTone}) {
    return hasTone ? [1, 2, 3, 4, 5] : [1, 2, 5];
  }

  bool isAnswered(int question) {
    switch (question) {
      case 1:
        return sleepiness != null && sleepiness! >= 1 && sleepiness! <= 9;
      case 2:
        return sleepInertiaOptions.containsKey(sleepInertia);
      case 3:
        return toneRelaxing != null && toneRelaxing! >= 1 && toneRelaxing! <= 5;
      case 4:
        return toneReuseOptions.containsKey(toneReuse);
      case 5:
        return sleepFactors.isNotEmpty &&
            sleepFactors.every(sleepFactorOptions.containsKey) &&
            (!sleepFactors.contains('none') || sleepFactors.length == 1);
      default:
        return false;
    }
  }

  bool validate({required bool hasTone}) {
    return questionsFor(hasTone: hasTone).every(isAnswered);
  }

  factory RestReview.fromMap(Map<String, dynamic> data) {
    return RestReview(
      sleepiness: (data['sleepiness'] as num?)?.toInt(),
      sleepInertia: data['sleepInertia'],
      toneRelaxing: (data['toneRelaxing'] as num?)?.toInt(),
      toneReuse: data['toneReuse'],
      sleepFactors: List<String>.from(data['sleepFactors'] ?? []),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sleepiness': sleepiness,
      'sleepInertia': sleepInertia,
      if (toneRelaxing != null) 'toneRelaxing': toneRelaxing,
      if (toneReuse != null) 'toneReuse': toneReuse,
      'sleepFactors': sleepFactors,
      'submittedAt': submittedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(submittedAt!),
    };
  }
}

class SessionAlarm {
  final DateTime wakeAt;
  final int window;
  final bool smart;
  final int repeats;

  const SessionAlarm({
    required this.wakeAt,
    required this.window,
    required this.smart,
    required this.repeats,
  });

  DateTime get windowStart =>
      smart ? wakeAt.subtract(Duration(minutes: window)) : wakeAt;

  String toMessage(String sessionId) {
    return '$sessionId|${wakeAt.millisecondsSinceEpoch}|$window|${smart ? 1 : 0}|$repeats';
  }

  factory SessionAlarm.fromMap(Map<String, dynamic> data) {
    return SessionAlarm(
      wakeAt: (data['wakeAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      window: (data['window'] as num? ?? 0).toInt(),
      smart: data['smart'] == true,
      repeats: (data['repeats'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wakeAt': Timestamp.fromDate(wakeAt),
      'window': window,
      'smart': smart,
      'repeats': repeats,
    };
  }
}

class SleepSession {
  final String sessionId;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> rawDataPaths;
  final SleepSummary? summary;
  final RestReview? restReview;
  final String? toneId;
  final SessionAlarm? alarm;
  final String? alarmTrigger;
  final String? modelVersion;

  const SleepSession({
    required this.sessionId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.rawDataPaths = const [],
    this.summary,
    this.restReview,
    this.toneId,
    this.alarm,
    this.alarmTrigger,
    this.modelVersion,
  });

  bool get isActive => status == 'active';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get hasTone => toneId != null && toneId!.isNotEmpty;

  factory SleepSession.fromMap(String sessionId, Map<String, dynamic> data) {
    return SleepSession(
      sessionId: sessionId,
      status: data['status'] ?? 'active',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      rawDataPaths: List<String>.from(data['rawDataPaths'] ?? []),
      summary: data['summary'] == null
          ? null
          : SleepSummary.fromMap(Map<String, dynamic>.from(data['summary'])),
      restReview: data['restReview'] == null
          ? null
          : RestReview.fromMap(Map<String, dynamic>.from(data['restReview'])),
      toneId: data['toneId'],
      alarm: data['alarm'] == null
          ? null
          : SessionAlarm.fromMap(Map<String, dynamic>.from(data['alarm'])),
      alarmTrigger: data['alarmTrigger'],
      modelVersion: data['modelVersion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime == null ? null : Timestamp.fromDate(endTime!),
      'rawDataPaths': rawDataPaths,
      'summary': summary?.toMap(),
      'restReview': restReview?.toMap(),
      'toneId': toneId,
      'alarm': alarm?.toMap(),
      'alarmTrigger': alarmTrigger,
      'modelVersion': modelVersion,
    };
  }
}
