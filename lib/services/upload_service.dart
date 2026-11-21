import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'session_service.dart';

class UploadService {
  static const Duration _retryDelay = Duration(minutes: 1);
  static Timer? _retryTimer;
  static bool _running = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SessionService _sessionService = SessionService();

  Future<List<File>> _pendingFiles() async {
    final base = await getApplicationSupportDirectory();
    final folder = Directory('${base.path}/sessions');
    if (!await folder.exists()) return [];
    return folder
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.zip'))
        .where((file) => !file.uri.pathSegments.last.startsWith('local-'))
        .toList();
  }

  String _sessionIdOf(File file) {
    final name = file.uri.pathSegments.last;
    return name.substring(0, name.length - '.zip'.length);
  }

  Future<List<File>> _ownedFiles() async {
    final owned = <File>[];
    for (final file in await _pendingFiles()) {
      if (await _sessionService.sessionExists(_sessionIdOf(file))) {
        owned.add(file);
      }
    }
    return owned;
  }

  Future<int> pendingCount() async {
    if (_auth.currentUser == null) return 0;
    return (await _ownedFiles()).length;
  }

  Future<int> uploadPending() async {
    final user = _auth.currentUser;
    if (user == null || _running) return 0;
    _running = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _storage.setMaxUploadRetryTime(const Duration(minutes: 2));

    var uploaded = 0;
    var failed = false;
    try {
      for (final file in await _ownedFiles()) {
        final sessionId = _sessionIdOf(file);
        final path = 'raw/${user.uid}/$sessionId/session.zip';
        try {
          await _storage
              .ref(path)
              .putFile(file, SettableMetadata(contentType: 'application/zip'));
          await _sessionService.markUploaded(sessionId, path);
          await file.delete();
          uploaded++;
        } catch (_) {
          failed = true;
        }
      }
    } catch (_) {
      failed = true;
    } finally {
      _running = false;
    }

    if (failed) {
      _retryTimer = Timer(_retryDelay, () => uploadPending());
    }
    return uploaded;
  }
}