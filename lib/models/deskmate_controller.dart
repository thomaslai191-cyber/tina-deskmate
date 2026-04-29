/// Tina DeskMate 主 Controller
/// GetX 狀態管理，協調所有服務

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deskmate_state.dart';
import '../services/websocket_service.dart';
import '../services/camera_service.dart';
import '../services/tts_service.dart';

class DeskMateController extends GetxController {
  // ── 服務 ──
  final WebSocketService wsService = WebSocketService();
  final CameraService cameraService = CameraService();
  final TtsService ttsService = TtsService();

  // ── 反應式狀態 ──
  final connectionState = AppConnectionState.disconnected.obs;
  final currentFace = TinaFace.idle.obs;
  final serverStatus = Rxn<ServerStatus>();
  final isStreaming = false.obs;
  final frameCount = 0.obs;
  final statusMessage = ''.obs;

  // 對話記錄
  final conversations = <Map<String, String>>[].obs;

  // Vision 分析結果
  final lastVisionAnalysis = ''.obs;

  // 設定
  final serverHost = ''.obs;
  final serverPort = 8765.obs;
  final autoConnect = false.obs;
  final streamFps = 5.obs;

  // ── 生命週期 ──
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _setupCallbacks();
  }

  @override
  void onClose() {
    cameraService.dispose();
    ttsService.dispose();
    wsService.disconnect();
    super.onClose();
  }

  // ── 設定 ──
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      serverHost.value = prefs.getString('server_host') ?? '';
      serverPort.value = prefs.getInt('server_port') ?? 8765;
      autoConnect.value = prefs.getBool('auto_connect') ?? false;
      streamFps.value = prefs.getInt('stream_fps') ?? 5;

      if (autoConnect.value && serverHost.value.isNotEmpty) {
        connectToServer();
      }
    } catch (e) {
      print('讀取設定失敗: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_host', serverHost.value);
      await prefs.setInt('server_port', serverPort.value);
      await prefs.setBool('auto_connect', autoConnect.value);
      await prefs.setInt('stream_fps', streamFps.value);
    } catch (e) {
      print('儲存設定失敗: $e');
    }
  }

  // ── 回調綁定 ──
  void _setupCallbacks() {
    wsService.onConnectionChange = (state) {
      connectionState.value = state;
      if (state == AppConnectionState.connected) {
        currentFace.value = TinaFace.happy;
        statusMessage.value = '已連線到 PC 💻';
      } else if (state == AppConnectionState.disconnected) {
        currentFace.value = TinaFace.idle;
        statusMessage.value = '未連線';
      } else if (state == AppConnectionState.connecting) {
        currentFace.value = TinaFace.thinking;
        statusMessage.value = '連線中...';
      } else {
        currentFace.value = TinaFace.error;
        statusMessage.value = '連線錯誤';
      }
    };

    wsService.onStatusUpdate = (status) {
      serverStatus.value = status;
    };

    wsService.onVisionAnalysis = (analysis) {
      lastVisionAnalysis.value = analysis;
      conversations.add({
        'role': 'tina',
        'text': analysis,
        'time': DateTime.now().toString().substring(11, 19),
      });
      currentFace.value = TinaFace.happy;
    };

    wsService.onError = (error) {
      statusMessage.value = '錯誤: $error';
      currentFace.value = TinaFace.error;
    };

    cameraService.onFrame = (b64) {
      wsService.sendFrame(b64);
    };

    cameraService.onFrameCount = (count) {
      frameCount.value = count;
    };
  }

  // ── 連線管理 ──
  Future<void> connectToServer() async {
    if (serverHost.value.isEmpty) {
      statusMessage.value = '請先設定 PC IP 位址';
      return;
    }

    currentFace.value = TinaFace.thinking;
    statusMessage.value = '連線到 ${serverHost.value}:${serverPort.value}...';

    final success = await wsService.connect(
      serverHost.value,
      port: serverPort.value,
    );

    if (success) {
      await saveSettings();

      // 自動啟動相機串流
      await initCamera();
      startStreaming();

      // Tina 打招呼
      await ttsService.initialize();
      ttsService.greet();
    }
  }

  Future<void> disconnect() async {
    cameraService.stopStreaming();
    isStreaming.value = false;
    await wsService.disconnect();
    statusMessage.value = '已離線';
  }

  // ── 相機 ──
  Future<bool> initCamera() async {
    final success = await cameraService.initialize(
      direction: CameraLensDirection.front,
    );
    return success;
  }

  void startStreaming() {
    if (!cameraService.isInitialized) return;
    cameraService.startStreaming(fps: streamFps.value);
    isStreaming.value = true;
    statusMessage.value = '串流中 📸 (${frameCount.value} 幀)';
    currentFace.value = TinaFace.listening;
  }

  void stopStreaming() {
    cameraService.stopStreaming();
    isStreaming.value = false;
    statusMessage.value = '串流暫停';
  }

  void toggleStreaming() {
    if (isStreaming.value) {
      stopStreaming();
    } else {
      startStreaming();
    }
  }

  Future<void> switchCamera() async {
    await cameraService.switchCamera();
  }

  // ── 命令 ──
  void sendAsk(String text) {
    if (text.isEmpty) return;

    conversations.add({
      'role': 'user',
      'text': text,
      'time': DateTime.now().toString().substring(11, 19),
    });

    currentFace.value = TinaFace.thinking;
    wsService.ask(text);
    statusMessage.value = '思考中...';
  }

  void takeScreenshot() {
    wsService.requestScreenshot();
    statusMessage.value = '截圖中...';
  }

  void toggleWatchMode() {
    wsService.toggleMode();
    statusMessage.value = '切換模式';
  }

  // ── Tina 表情 ──
  void setFace(TinaFace face) {
    currentFace.value = face;
  }

  void say(String text) {
    conversations.add({
      'role': 'tina',
      'text': text,
      'time': DateTime.now().toString().substring(11, 19),
    });
    ttsService.speak(text);
  }

  // ── 輔助 ──
  bool get isConnected => connectionState.value == AppConnectionState.connected;

  String get connectionLabel {
    switch (connectionState.value) {
      case AppConnectionState.disconnected:
        return '未連線';
      case AppConnectionState.connecting:
        return '連線中...';
      case AppConnectionState.connected:
        return '已連線';
      case AppConnectionState.error:
        return '連線錯誤';
    }
  }
}
