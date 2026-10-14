import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'session_service.dart';

class UploadService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SessionService _sessionService = SessionService();

  Future<int> uploadPending() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final base = await getApplicationSupportDirectory();
    final folder = Directory('${base.path}/sessions');
    if (!await folder.exists()) return 0;

    final files = folder
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.zip'))
        .toList();

    var uploaded = 0;
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final sessionId = name.substring(0, name.length - '.zip'.length);
      if (sessionId.startsWith('local-')) continue;

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
