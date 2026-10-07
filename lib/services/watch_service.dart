import 'package:flutter/services.dart';

class WatchInfo {
  final String id;
  final String name;

  const WatchInfo({required this.id, required this.name});
}

class WatchService {
  static const _channel = MethodChannel('somnia/watch');

  Future<WatchInfo?> findWatch() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('findWatch');
      if (result == null) return null;
      return WatchInfo(
        id: result['id'] as String? ?? '',
        name: result['name'] as String? ?? 'Galaxy Watch',
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _send(String path, String data) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'send',
        {'path': path, 'data': data},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startRecording(String sessionId) {
    return _send('/somnia/start', sessionId);
  }

  Future<bool> stopRecording(String sessionId) {
    return _send('/somnia/stop', sessionId);
  }
}