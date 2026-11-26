import 'package:flutter/services.dart';

import '../models/sleep_session.dart';

class WatchInfo {
  final String id;
  final String name;

  const WatchInfo({required this.id, required this.name});
}

class WatchService {
  static const _channel = MethodChannel('somnia/watch');

  Future<WatchInfo?> findWatch() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'findWatch',
      );
      if (result == null) return null;
      return WatchInfo(
        id: result['id'] as String? ?? '',
        name: result['name'] as String? ?? 'Galaxy Watch',
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _sendAndWait(
    String method,
    String path,
    String data,
    String sessionId,
  ) async {
    try {
      final ok = await _channel.invokeMethod<bool>(method, {
        'path': path,
        'data': data,
        'sessionId': sessionId,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startRecording(String sessionId, {SessionAlarm? alarm}) {
    return _sendAndWait(
      'startAndWait',
      '/somnia/start',
      alarm == null ? sessionId : alarm.toMessage(sessionId),
      sessionId,
    );
  }

  Future<bool> stopRecording(String sessionId) {
    return _sendAndWait('stopAndWait', '/somnia/stop', sessionId, sessionId);
  }
}