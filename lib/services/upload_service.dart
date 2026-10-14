import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'session_service.dart';

class UploadService {
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

  Future<int> pendingCount() async {
    return (await _pendingFiles()).length;
  }

  Future<int> uploadPending() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    _storage.setMaxUploadRetryTime(const Duration(seconds: 30));

    var uploaded = 0;
    for (final file in await _pendingFiles()) {
      final name = file.uri.pathSegments.last;
      final sessionId = name.substring(0, name.length - '.zip'.length);
      final path = 'raw/${user.uid}/$sessionId/session.zip';
      try {
        await _storage
            .ref(path)
            .putFile(file, SettableMetadata(contentType: 'application/zip'));
        await _sessionService.addRawDataPath(sessionId, path);
        await file.delete();
        uploaded++;
      } catch (_) {}
    }
    return uploaded;
  }
}