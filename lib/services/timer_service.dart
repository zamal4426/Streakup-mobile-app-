import 'dart:async';
import 'package:flutter/material.dart';
import 'celebration_sound.dart';

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._();
  factory TimerService() => _instance;
  TimerService._();

  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _hasStarted = false;
  String _habitName = '';
  Color _color = Colors.blue;

  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  bool get hasStarted => _hasStarted;
  bool get isDone => _hasStarted && _remainingSeconds == 0 && !_isRunning;
  bool get isActive => _hasStarted && !isDone;
  String get habitName => _habitName;
  Color get color => _color;

  double get progress {
    if (!_hasStarted || _totalSeconds == 0) return 0.0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  String get formattedTime {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void start(int minutes, String habitName, Color color) {
    _timer?.cancel();
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    _isRunning = true;
    _hasStarted = true;
    _habitName = habitName;
    _color = color;
    _tick();
    notifyListeners();
  }

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _isRunning = false;
        CelebrationSound.playTimerEnd();
        notifyListeners();
        return;
      }
      _remainingSeconds--;
      notifyListeners();
    });
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resume() {
    _isRunning = true;
    _tick();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _hasStarted = false;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    _habitName = '';
    notifyListeners();
  }
}
