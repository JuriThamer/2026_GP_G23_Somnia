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

  Future<String> startSession({SessionAlarm? alarm, String? toneId}) async {
    final doc = await _sessions.add({
      'status': 'active',
      'startTime': FieldValue.serverTimestamp(),
      'alarm': alarm?.toMap(),
      'toneId': toneId,
    });
    return doc.id;
  }

  Future<void> endSession(String sessionId) async {
    await _sessions.doc(sessionId).update({'endTime': Timestamp.now()});
  }

  Future<void> markUploaded(String sessionId, String path) async {
    final session = _sessions.doc(sessionId);
    final epochs = await session.collection('wakeWindowEpochs').get();
    final batch = _db.batch();
    batch.update(session, {
      'status': 'processing',
      'rawDataPath': {'path': path, 'uploadedAt': FieldValue.serverTimestamp()},
    });
    for (final epoch in epochs.docs) {
      batch.delete(epoch.reference);
    }
    await batch.commit();
  }

  Future<bool> sessionExists(String sessionId) async {
    final doc = await _sessions.doc(sessionId).get();
    return doc.exists;
  }

  Future<SleepSession?> getSession(String sessionId) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;
    return SleepSession.fromMap(doc.id, doc.data()!);
  }

  Future<SleepSession?> getActiveSession() async {
    final result = await _sessions.where('status', isEqualTo: 'active').get();
    for (final doc in result.docs) {
      final session = SleepSession.fromMap(doc.id, doc.data());
      if (session.isActive) return session;
    }
    return null;
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

  Future<void> saveRestReview(String sessionId, RestReview restReview) async {
    await _sessions.doc(sessionId).update({'restReview': restReview.toMap()});
  }
}
