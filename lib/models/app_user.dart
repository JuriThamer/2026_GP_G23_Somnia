import 'package:cloud_firestore/cloud_firestore.dart';

import 'alarm.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String themeMode;
  final Map<String, dynamic>? watch;
  final Alarm alarm;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.themeMode = 'dark',
    this.watch,
    this.alarm = const Alarm(),
    this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      themeMode: data['themeMode'] ?? 'dark',
      watch: data['watch'] == null
          ? null
          : Map<String, dynamic>.from(data['watch']),
      alarm: data['alarm'] == null
          ? const Alarm()
          : Alarm.fromMap(Map<String, dynamic>.from(data['alarm'])),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'themeMode': themeMode,
      'watch': watch,
      'alarm': alarm.toMap(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
}
