import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sleep_session.dart';

class SessionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessions {
    return _db
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('sleepSessions');
  }

  Future<String> startSession() async {
    final doc = await _sessions.add({
      'status': 'active',
      'startTime': FieldValue.serverTimestamp(),
      'rawDataPaths': <String>[],
    });
    return doc.id;
  }

  Future<void> endSession(String sessionId) async {
    await _sessions.doc(sessionId).update({
      'status': 'processing',
      'endTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addRawDataPath(String sessionId, String path) async {
    await _sessions.doc(sessionId).update({
      'rawDataPaths': FieldValue.arrayUnion([path]),
    });
  }

  Future<SleepSession?> getSession(String sessionId) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;
    return SleepSession.fromMap(doc.id, doc.data()!);
  }

  Future<SleepSession?> getActiveSession() async {
    final result = await _sessions
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (result.docs.isEmpty) return null;
    final doc = result.docs.first;
    return SleepSession.fromMap(doc.id, doc.data());
  }

  Future<List<SleepSession>> getSessions({int limit = 30}) async {
    final result = await _sessions
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();
    return result.docs
        .map((doc) => SleepSession.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<SleepSession>> getCompletedSessions({int limit = 30}) async {
    final all = await getSessions(limit: limit);
    return all.where((session) => session.isCompleted).toList();
  }

  Future<SleepSession?> getLatestCompleted() async {
    final completed = await getCompletedSessions();
    return completed.isEmpty ? null : completed.first;
  }

  Stream<List<SleepSession>> watchSessions({int limit = 30}) {
    return _sessions
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (result) => result.docs
              .map((doc) => SleepSession.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> saveQuestionnaire(
    String sessionId,
    Questionnaire questionnaire,
  ) async {
    await _sessions.doc(sessionId).update({
      'questionnaire': questionnaire.toMap(),
    });
  }
}
