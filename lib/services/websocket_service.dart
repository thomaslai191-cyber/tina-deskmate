/// WebSocket 服務 — 手機與 PC 伺服器之間的通訊核心
///
/// 職責：
/// 1. 建立/維護 WebSocket 連線
/// 2. 發送相機幀到伺服器
/// 3. 發送命令並接收回應
/// 4. 接收 Vision 分析結果
/// 5. 心跳保持連線

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/deskmate_state.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  String _host = '';
  int _port = 8765;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _heartbeatInterval = 15; // 秒

  // 回調
  Function(ServerStatus)? onStatusUpdate;
  Function(String)? onVisionAnalysis;
  Function(AppConnectionState)? onConnectionChange;
  Function(String)? onError;

  /// 連線到 PC 伺服器
  Future<bool> connect(String host, {int port = 8765}) async {
    if (_isConnected) await disconnect();

    _host = host;
    _port = port;
    _reconnectAttempts = 0;

    onConnectionChange?.call(AppConnectionState.connecting);

    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);

      // 等待連線確認
      await _channel!.ready;

      _isConnected = true;
      _reconnectAttempts = 0;
      onConnectionChange?.call(AppConnectionState.connected);

      // 註冊為手機設備
      _send({
        'type': 'register',
        'device': 'phone',
      });

      // 啟動心跳
      _startHeartbeat();

      // 監聽訊息
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (error) {
          _isConnected = false;
          onConnectionChange?.call(AppConnectionState.error);
          onError?.call('WS 錯誤: $error');
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          onConnectionChange?.call(AppConnectionState.disconnected);
          _scheduleReconnect();
        },
      );

      return true;
    } catch (e) {
      _isConnected = false;
      onConnectionChange?.call(AppConnectionState.error);
      onError?.call('連線失敗: $e');
      _scheduleReconnect();
      return false;
    }
  }

  /// 斷開連線
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    onConnectionChange?.call(AppConnectionState.disconnected);
  }

  /// 發送相機幀
  void sendFrame(String base64Data) {
    if (!_isConnected) return;
    _send({
      'type': 'frame',
      'data': base64Data,
    });
  }

  /// 發送命令
  void sendCommand(String action, {Map<String, dynamic>? data}) {
    if (!_isConnected) return;
    _send({
      'type': 'command',
      'command': {
        'action': action,
        'data': data ?? {},
      },
    });
  }

  /// 發送詢問（含截圖）
  void ask(String text) {
    sendCommand('ask', data: {'text': text});
  }

  /// 請求截圖
  void requestScreenshot() {
    sendCommand('screenshot');
  }

  /// 切換監視模式
  void toggleMode() {
    sendCommand('toggle_mode');
  }

  /// 發送 Vision 分析結果到伺服器
  void sendVisionResult(String analysis) {
    if (!_isConnected) return;
    _send({
      'type': 'vision_result',
      'analysis': analysis,
    });
  }

  // ── 內部方法 ──

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      onError?.call('發送失敗: $e');
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'hello':
          print('🟢 伺服器回應: ${msg['server']} v${msg['version']}');
          break;

        case 'registered':
          print('✅ 已註冊為 ${msg['device']}');
          break;

        case 'frame_ack':
          // 伺服器確認收到幀
          break;

        case 'command_result':
          final result = msg['result'] as Map<String, dynamic>?;
          if (result != null) {
            // 如果有截圖路徑，回調讓 UI 層處理
            final screenPath = result['screen_path'] as String?;
            if (screenPath != null && screenPath.isNotEmpty) {
              // 可以請求 vision_analyze
            }
          }
          break;

        case 'vision_analysis':
          final analysis = msg['analysis'] as String?;
          if (analysis != null && analysis.isNotEmpty) {
            onVisionAnalysis?.call(analysis);
          }
          break;

        case 'status':
          final data = msg['data'] as Map<String, dynamic>?;
          if (data != null) {
            onStatusUpdate?.call(ServerStatus.fromJson(data));
          }
          break;

        case 'pong':
          // 心跳回應
          break;

        case 'error':
          onError?.call(msg['error'] as String? ?? '未知錯誤');
          break;
      }
    } catch (e) {
      print('⚠️ 訊息解析錯誤: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: _heartbeatInterval),
      (_) {
        if (_isConnected) {
          _send({'type': 'ping'});
        }
      },
    );
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      onError?.call('重新連線次數已達上限，請手動重連');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delay = (_reconnectAttempts * 2).clamp(1, 30);

    print('🔄 ${_reconnectAttempts}/${_maxReconnectAttempts} 次重連，${delay}秒後...');
    onConnectionChange?.call(AppConnectionState.connecting);

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      connect(_host, port: _port);
    });
  }

  bool get isConnected => _isConnected;
  int get reconnectAttempts => _reconnectAttempts;
}
