/// Tina DeskMate 狀態模型
/// 定義 App 全域狀態的資料結構

/// Tina 的表情
enum TinaFace {
  idle,       // 😊 一般狀態
  happy,      // 😄 開心跳躍
  thinking,   // 🤔 思考中
  listening,  // 👂 聽你說話
  working,    // 💪 工作中
  error,      // 😅 出錯了
  wave,       // 👋 打招呼
  love,       // ❤️ 開心
}

/// Tina Face 對應的 Emoji
const Map<TinaFace, String> tinaFaceEmoji = {
  TinaFace.idle: '😊',
  TinaFace.happy: '😄',
  TinaFace.thinking: '🤔',
  TinaFace.listening: '👂',
  TinaFace.working: '💪',
  TinaFace.error: '😅',
  TinaFace.wave: '👋',
  TinaFace.love: '❤️',
};

/// Tina Face 對應的顏色
const Map<TinaFace, int> tinaFaceColor = {
  TinaFace.idle: 0xFF6C63FF,      // 紫色
  TinaFace.happy: 0xFFF6C90E,     // 金色
  TinaFace.thinking: 0xFF4FC3F7,  // 藍色
  TinaFace.listening: 0xFF81C784, // 綠色
  TinaFace.working: 0xFFFF7043,   // 橘色
  TinaFace.error: 0xFFE57373,     // 紅色
  TinaFace.wave: 0xFFBA68C8,      // 紫色
  TinaFace.love: 0xFFF06292,      // 粉色
};

/// 伺服器命令回應
class CommandResult {
  final bool success;
  final String action;
  final String? error;
  final Map<String, dynamic>? data;

  CommandResult({
    required this.success,
    required this.action,
    this.error,
    this.data,
  });

  factory CommandResult.fromJson(Map<String, dynamic> json) {
    return CommandResult(
      success: json['success'] ?? false,
      action: json['action'] ?? '',
      error: json['error'],
      data: json['result'] is Map ? json['result'] as Map<String, dynamic> : null,
    );
  }
}

/// 伺服器狀態
class ServerStatus {
  final String mode;
  final int attention;
  final String activeWindow;
  final double uptime;

  ServerStatus({
    this.mode = 'idle',
    this.attention = 0,
    this.activeWindow = '',
    this.uptime = 0,
  });

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      mode: json['mode'] ?? 'idle',
      attention: json['attention'] ?? 0,
      activeWindow: json['active_window'] ?? '',
      uptime: (json['uptime'] ?? 0).toDouble(),
    );
  }
}

/// 連線狀態
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}
