import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/tranquil_tone.dart';

class ToneService extends ChangeNotifier {
  ToneService._() {
    _player.playingStream.listen(_onPlayingChanged);
  }

  static final ToneService instance = ToneService._();

  static const List<int> timerOptions = [10, 15, 30, 60, 120, 180, 480];

  final AudioPlayer _player = AudioPlayer();

  TranquilTone? _currentTone;
  bool _loaded = false;
  bool _isPlaying = false;
  int _timerMinutes = 60;
  Duration _elapsedBefore = Duration.zero;
  DateTime? _startedAt;
  Timer? _stopTimer;

  TranquilTone? get currentTone => _currentTone;
  bool get isPlaying => _isPlaying;
  int get timerMinutes => _timerMinutes;
  String? get playingToneId => _isPlaying ? _currentTone?.toneId : null;

  Duration get elapsed {
    final running = _isPlaying && _startedAt != null
        ? DateTime.now().difference(_startedAt!)
        : Duration.zero;
    return _elapsedBefore + running;
  }

  Future<List<TranquilTone>> getTones() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tranquilTones')
        .get();

    final tones = snapshot.docs
        .map((doc) => TranquilTone.fromMap(doc.id, doc.data()))
        .where((tone) => tone.title.isNotEmpty && tone.storagePath.isNotEmpty)
        .toList();

    tones.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    return tones;
  }

  Future<void> play(TranquilTone tone) async {
    if (!_loaded || _currentTone?.toneId != tone.toneId) {
      final url = await FirebaseStorage.instance
          .ref(tone.storagePath)
          .getDownloadURL();

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(id: tone.toneId, title: tone.title, album: 'Somnia'),
        ),
      );
      await _player.setLoopMode(LoopMode.one);

      _currentTone = tone;
      _loaded = true;
      _elapsedBefore = Duration.zero;
    }

    _isPlaying = true;
    _startedAt = DateTime.now();
    _scheduleStop();
    notifyListeners();

    unawaited(_player.play());
  }

  Future<void> pause() async {
    if (!_isPlaying) return;

    _elapsedBefore = elapsed;
    _isPlaying = false;
    _startedAt = null;
    _stopTimer?.cancel();
    notifyListeners();

    await _player.pause();
  }

  Future<void> stop() async {
    _isPlaying = false;
    _loaded = false;
    _startedAt = null;
    _elapsedBefore = Duration.zero;
    _stopTimer?.cancel();
    notifyListeners();

    await _player.stop();
  }

  void setTimer(int minutes) {
    _timerMinutes = minutes;

    if (_isPlaying) {
      _scheduleStop();
    }

    notifyListeners();
  }

  void _scheduleStop() {
    _stopTimer?.cancel();

    final remaining = Duration(minutes: _timerMinutes) - elapsed;

    if (remaining <= Duration.zero) {
      unawaited(stop());
      return;
    }

    _stopTimer = Timer(remaining, () => unawaited(stop()));
  }

  void _onPlayingChanged(bool playing) {
    if (playing == _isPlaying) return;

    if (playing) {
      _isPlaying = true;
      _startedAt = DateTime.now();
      _scheduleStop();
    } else {
      _elapsedBefore = elapsed;
      _isPlaying = false;
      _startedAt = null;
      _stopTimer?.cancel();
    }

    notifyListeners();
  }
}
