/// TTS 語音服務 — Tina 用語音跟你說話

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// 初始化 TTS
  Future<bool> initialize() async {
    try {
      // 設定語言
      await _tts.setLanguage('zh-TW');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.1); // 輕柔一點
      await _tts.setVolume(1.0);

      // 狀態回調
      _tts.setStartHandler(() {
        _isSpeaking = true;
      });
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        print('TTS 錯誤: $msg');
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      print('TTS 初始化失敗: $e');
      return false;
    }
  }

  /// 說話
  Future<void> speak(String text) async {
    if (!_isInitialized) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      print('TTS speak 錯誤: $e');
    }
  }

  /// 停止說話
  Future<void> stop() async {
    if (!_isInitialized) return;
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Tina 打招呼
  Future<void> greet() async {
    final greetings = [
      '嗨 Thomas，我準備好了！',
      'Thomas 你好，隨時聽候差遣！',
      '歡迎回來！我一直在等你。',
    ];
    final greeting = greetings[DateTime.now().second % greetings.length];
    await speak(greeting);
  }

  Future<void> dispose() async {
    await stop();
  }

  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isInitialized;
}
