/// 相機服務 — 管理手機相機並提供幀給 WebSocket 串流
///
/// 使用 camera package 捕獲即時畫面
/// 壓縮後以 base64 傳送

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isStreaming = false;
  Timer? _frameTimer;
  int _frameCount = 0;

  // 回調：發送幀到 WebSocket
  Function(String base64)? onFrame;

  // 回調：幀計數
  Function(int count)? onFrameCount;

  /// 初始化相機
  Future<bool> initialize({CameraLensDirection direction = CameraLensDirection.back}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print('❌ 找不到相機');
        return false;
      }

      // 選擇指定方向的相機
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // 平衡品質與速度
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      print('✅ 相機初始化完成: ${camera.name} (${_controller!.value.previewSize})');
      return true;
    } catch (e) {
      print('❌ 相機初始化失敗: $e');
      return false;
    }
  }

  /// 開始串流（定時捕獲幀）
  void startStreaming({int fps = 5}) {
    if (_isStreaming || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    _isStreaming = true;
    final interval = Duration(milliseconds: (1000 / fps).round());

    _frameTimer = Timer.periodic(interval, (_) => _captureFrame());
    print('📸 串流開始: ${fps}fps');
  }

  /// 停止串流
  void stopStreaming() {
    _isStreaming = false;
    _frameTimer?.cancel();
    _frameTimer = null;
    print('⏸️ 串流停止');
  }

  /// 捕獲一幀並發送
  Future<void> _captureFrame() async {
    if (!_isStreaming || _controller == null) return;

    try {
      final xFile = await _controller!.takePicture();
      final bytes = await xFile.readAsBytes();

      // 壓縮：如果太大就降低品質
      Uint8List compressed = bytes;
      if (bytes.length > 200 * 1024) {
        // 用 Flutter 的 decodeImage 壓縮
        final codec = await ui.instantiateImageCodec(bytes,
          targetWidth: 640,
          targetHeight: 480,
        );
        final frameInfo = await codec.getNextFrame();
        final byteData = await frameInfo.image.toByteData(
          format: ui.ImageByteFormat.jpeg,
          quality: 60,
        );
        if (byteData != null) {
          compressed = byteData.buffer.asUint8List();
        }
      }

      // base64 編碼
      final b64 = base64Encode(compressed);
      onFrame?.call(b64);

      _frameCount++;
      if (_frameCount % 10 == 0) {
        onFrameCount?.call(_frameCount);
      }
    } catch (e) {
      // 忽略短暫錯誤（相機忙碌時偶爾會跳）
    }
  }

  /// 切換前後鏡頭
  Future<bool> switchCamera() async {
    if (_cameras.length < 2) return false;

    final currentDir = _controller?.description.lensDirection;
    final newDir = currentDir == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final wasStreaming = _isStreaming;
    stopStreaming();

    await _controller?.dispose();

    final success = await initialize(direction: newDir);
    if (success && wasStreaming) {
      startStreaming();
    }
    return success;
  }

  /// 獲取相機預覽 Widget
  Widget? get previewWidget {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    return CameraPreview(_controller!);
  }

  /// 釋放資源
  Future<void> dispose() async {
    stopStreaming();
    await _controller?.dispose();
    _controller = null;
  }

  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isStreaming => _isStreaming;
  int get frameCount => _frameCount;
}
