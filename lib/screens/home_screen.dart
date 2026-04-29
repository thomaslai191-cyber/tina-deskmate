/// 主畫面 — Tina DeskMate 桌面伴侶
///
/// 功能：
/// - 顯示 Tina 表情（大臉）
/// - 連線狀態指示
/// - 相機串流控制
/// - 語音輸入 / 文字輸入
/// - 對話歷史

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/deskmate_controller.dart';
import '../models/deskmate_state.dart';
import '../widgets/tina_face_widget.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final DeskMateController ctrl = Get.put(DeskMateController());
  final TextEditingController textCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    // Tina 大臉
                    Obx(() => TinaFaceWidget(
                      face: ctrl.currentFace.value,
                      size: MediaQuery.of(context).size.width * 0.6,
                      onTap: () => _onTinaTap(),
                    )),
                    SizedBox(height: 12),
                    // 狀態訊息
                    Obx(() => Text(
                      ctrl.statusMessage.value,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    )),
                    SizedBox(height: 8),
                    // 連線狀態
                    Obx(() => _buildConnectionBadge()),
                    SizedBox(height: 12),
                    // 控制按鈕列
                    _buildControlRow(),
                    if (ctrl.isConnected) ...[
                      SizedBox(height: 16),
                      // 串流狀態
                      Obx(() => _buildStreamInfo()),
                    ],
                    SizedBox(height: 20),
                    // 快速問候
                    _buildQuickActions(),
                    SizedBox(height: 16),
                    // 對話記錄
                    Obx(() => _buildConversationList()),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // 底部輸入欄
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Logo + 標題
          Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
          SizedBox(width: 8),
          Text(
            'Tina DeskMate',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          // 設定按鈕
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white54),
            onPressed: () => Get.to(() => SettingsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge() {
    final state = ctrl.connectionState.value;
    
    Color bgColor;
    String label;
    
    switch (state) {
      case AppConnectionState.connected:
        bgColor = Colors.green;
        label = '已連線到 PC';
        break;
      case AppConnectionState.connecting:
        bgColor = Colors.orange;
        label = '連線中...';
        break;
      case AppConnectionState.error:
        bgColor = Colors.red;
        label = '連線失敗';
        break;
      case AppConnectionState.disconnected:
      default:
        bgColor = Colors.grey;
        label = '未連線';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              boxShadow: state == AppConnectionState.connected
                  ? [BoxShadow(color: bgColor, blurRadius: 8)]
                  : null,
            ),
          ),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildControlRow() {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 連線/斷線
        _controlButton(
          icon: ctrl.isConnected ? Icons.link_off : Icons.link,
          label: ctrl.isConnected ? '斷線' : '連線',
          color: ctrl.isConnected ? Colors.redAccent : Colors.green,
          onTap: () {
            if (ctrl.isConnected) {
              ctrl.disconnect();
            } else {
              _showConnectDialog();
            }
          },
        ),
        SizedBox(width: 12),
        // 串流切換
        _controlButton(
          icon: ctrl.isStreaming.value ? Icons.videocam : Icons.videocam_off,
          label: ctrl.isStreaming.value ? '停止串流' : '開始串流',
          color: ctrl.isStreaming.value ? Colors.orange : Colors.blue,
          onTap: ctrl.isConnected ? () => ctrl.toggleStreaming() : null,
          enabled: ctrl.isConnected,
        ),
        SizedBox(width: 12),
        // 截圖
        _controlButton(
          icon: Icons.screenshot,
          label: '截圖',
          color: Colors.cyan,
          onTap: ctrl.isConnected ? () => ctrl.takeScreenshot() : null,
          enabled: ctrl.isConnected,
        ),
      ],
    ));
  }

  Widget _buildStreamInfo() {
    if (!ctrl.isStreaming.value) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam, size: 16, color: Colors.green),
          SizedBox(width: 6),
          Text(
            '${ctrl.frameCount} 幀已傳送',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          SizedBox(width: 12),
          // 切換鏡頭
          InkWell(
            onTap: () => ctrl.switchCamera(),
            child: Icon(Icons.flip_camera_android, color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Obx(() {
      if (!ctrl.isConnected) return SizedBox.shrink();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _quickChip('👋 打招呼', () => ctrl.say('嗨！我在這裡！')),
          _quickChip('💻 在做什麼？', () => ctrl.sendAsk('你現在在做什麼？')),
          _quickChip('📊 狀態', () => ctrl.toggleWatchMode()),
          _quickChip('🧠 幫我看看', () => ctrl.sendAsk('幫我看一下我的螢幕，告訴我目前的情況')),
        ],
      );
    });
  }

  Widget _buildConversationList() {
    final items = ctrl.conversations;
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          '連線後 Tina 會看著你的螢幕幫助你 💪',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white30, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final msg = items[index];
        final isUser = msg['role'] == 'user';
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFF6C63FF).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Text('🤖', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF6C63FF).withOpacity(0.15),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] ?? '',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          msg['time'] ?? '',
                          style: TextStyle(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg['text'] ?? '',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          msg['time'] ?? '',
                          style: TextStyle(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Text('👤', style: TextStyle(fontSize: 16)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: textCtrl,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: ctrl.isConnected ? '問 Tina 問題...' : '先連線到 PC...',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                ),
                onSubmitted: (text) {
                  if (text.isNotEmpty && ctrl.isConnected) {
                    ctrl.sendAsk(text);
                    textCtrl.clear();
                  }
                },
              ),
            ),
          ),
          SizedBox(width: 8),
          Obx(() => CircleAvatar(
            backgroundColor: ctrl.isConnected
                ? Color(0xFF6C63FF)
                : Colors.grey,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                final text = textCtrl.text.trim();
                if (text.isNotEmpty && ctrl.isConnected) {
                  ctrl.sendAsk(text);
                  textCtrl.clear();
                }
              },
            ),
          )),
        ],
      ),
    );
  }

  // ── 輔助 Widgets ──

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? color : Colors.grey, size: 22),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white70 : Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String text, VoidCallback onTap) {
    return ActionChip(
      label: Text(text, style: TextStyle(color: Colors.white70, fontSize: 12)),
      backgroundColor: Colors.white.withOpacity(0.05),
      side: BorderSide(color: Colors.white.withOpacity(0.1)),
      onPressed: onTap,
      padding: EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _onTinaTap() {
    // 點 Tina 臉時隨機反應
    final faces = [
      TinaFace.happy,
      TinaFace.love,
      TinaFace.wave,
      TinaFace.thinking,
    ];
    ctrl.setFace(faces[DateTime.now().millisecondsSinceEpoch % faces.length]);
    ctrl.say('嗯？有什麼事嗎？');
  }

  void _showConnectDialog() {
    Get.dialog(AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: Text('連線到 PC', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: TextEditingController(text: ctrl.serverHost.value),
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'PC IP 位址',
              hintText: '例如 192.168.1.100',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
            onChanged: (v) => ctrl.serverHost.value = v,
          ),
          SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: ctrl.serverPort.value.toString()),
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Port',
              hintText: '8765',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
            onChanged: (v) {
              final port = int.tryParse(v);
              if (port != null) ctrl.serverPort.value = port;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('取消'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6C63FF),
          ),
          onPressed: () {
            Get.back();
            ctrl.connectToServer();
          },
          child: Text('連線'),
        ),
      ],
    ));
  }
}

// ============================================================
// 設定畫面
// ============================================================
class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final DeskMateController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('設定', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF16213E),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          // 伺服器設定
          _sectionHeader('伺服器'),
          _settingTile(
            icon: Icons.computer,
            title: 'PC IP 位址',
            subtitle: ctrl.serverHost.value.isEmpty ? '尚未設定' : ctrl.serverHost.value,
            onTap: () => _editHost(context),
          ),
          _settingTile(
            icon: Icons.router,
            title: 'Port',
            subtitle: '${ctrl.serverPort.value}',
            onTap: () => _editPort(context),
          ),
          Divider(color: Colors.white12, height: 30),

          // 相機設定
          _sectionHeader('相機'),
          Obx(() => SwitchListTile(
            title: Text('自動串流', style: TextStyle(color: Colors.white)),
            subtitle: Text('連線後自動啟動相機', style: TextStyle(color: Colors.white38)),
            value: ctrl.isStreaming.value,
            activeColor: Color(0xFF6C63FF),
            onChanged: (v) {
              if (v) ctrl.startStreaming();
              else ctrl.stopStreaming();
            },
          )),
          Obx(() => _settingTile(
            icon: Icons.speed,
            title: '串流影格率',
            subtitle: '${ctrl.streamFps.value} fps',
            onTap: () => _editFps(context),
          )),
          Divider(color: Colors.white12, height: 30),

          // 自動連線
          Obx(() => SwitchListTile(
            title: Text('開機自動連線', style: TextStyle(color: Colors.white)),
            subtitle: Text('App 啟動時自動連線到 PC', style: TextStyle(color: Colors.white38)),
            value: ctrl.autoConnect.value,
            activeColor: Color(0xFF6C63FF),
            onChanged: (v) {
              ctrl.autoConnect.value = v;
              ctrl.saveSettings();
            },
          )),
          Divider(color: Colors.white12, height: 30),

          // 關於
          _sectionHeader('關於'),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.white54),
            title: Text('Tina DeskMate v1.0.0', style: TextStyle(color: Colors.white)),
            subtitle: Text('桌面 AI 伴侶', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Color(0xFF6C63FF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54),
      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white38)),
      trailing: Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }

  void _editHost(BuildContext context) {
    final ctrl = Get.find<DeskMateController>();
    final tc = TextEditingController(text: ctrl.serverHost.value);
    
    Get.dialog(AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: Text('PC IP 位址', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: tc,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '例如 192.168.1.100',
          hintStyle: TextStyle(color: Colors.white30),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('取消')),
        ElevatedButton(
          onPressed: () {
            ctrl.serverHost.value = tc.text;
            ctrl.saveSettings();
            Get.back();
          },
          child: Text('儲存'),
        ),
      ],
    ));
  }

  void _editPort(BuildContext context) {
    final ctrl = Get.find<DeskMateController>();
    final tc = TextEditingController(text: ctrl.serverPort.value.toString());
    
    Get.dialog(AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: Text('Port', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: tc,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('取消')),
        ElevatedButton(
          onPressed: () {
            final port = int.tryParse(tc.text);
            if (port != null) {
              ctrl.serverPort.value = port;
              ctrl.saveSettings();
            }
            Get.back();
          },
          child: Text('儲存'),
        ),
      ],
    ));
  }

  void _editFps(BuildContext context) {
    final ctrl = Get.find<DeskMateController>();
    final tc = TextEditingController(text: ctrl.streamFps.value.toString());
    
    Get.dialog(AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: Text('串流影格率', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('建議 3-10 fps\n越高越耗電，但畫面越流暢', style: TextStyle(color: Colors.white38, fontSize: 12)),
          SizedBox(height: 12),
          TextField(
            controller: tc,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('取消')),
        ElevatedButton(
          onPressed: () {
            final fps = int.tryParse(tc.text);
            if (fps != null && fps >= 1 && fps <= 30) {
              ctrl.streamFps.value = fps;
              ctrl.saveSettings();
            }
            Get.back();
          },
          child: Text('儲存'),
        ),
      ],
    ));
  }
}
