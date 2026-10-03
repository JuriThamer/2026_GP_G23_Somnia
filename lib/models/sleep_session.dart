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

class Questionnaire {
  final int sleepQuality;
  final String feeling;
  final int easeOfWaking;
  final int easeOfFallingAsleep;
  final DateTime? submittedAt;

  const Questionnaire({
    required this.sleepQuality,
    required this.feeling,
    required this.easeOfWaking,
    required this.easeOfFallingAsleep,
    this.submittedAt,
  });

  factory Questionnaire.fromMap(Map<String, dynamic> data) {
    return Questionnaire(
      sleepQuality: (data['sleepQuality'] as num? ?? 0).toInt(),
      feeling: data['feeling'] ?? '',
      easeOfWaking: (data['easeOfWaking'] as num? ?? 0).toInt(),
      easeOfFallingAsleep: (data['easeOfFallingAsleep'] as num? ?? 0).toInt(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sleepQuality': sleepQuality,
      'feeling': feeling,
      'easeOfWaking': easeOfWaking,
      'easeOfFallingAsleep': easeOfFallingAsleep,
      'submittedAt': submittedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(submittedAt!),
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
  final Questionnaire? questionnaire;
  final String? alarmTrigger;
  final String? modelVersion;

  const SleepSession({
    required this.sessionId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.rawDataPaths = const [],
    this.summary,
    this.questionnaire,
    this.alarmTrigger,
    this.modelVersion,
  });

  bool get isActive => status == 'active';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

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
      questionnaire: data['questionnaire'] == null
          ? null
          : Questionnaire.fromMap(
              Map<String, dynamic>.from(data['questionnaire']),
            ),
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
      'questionnaire': questionnaire?.toMap(),
      'alarmTrigger': alarmTrigger,
      'modelVersion': modelVersion,
    };
  }
}
