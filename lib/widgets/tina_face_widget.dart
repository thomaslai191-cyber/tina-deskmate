/// Tina 表情 Widget — 顯示 Tina 的可愛大臉
///
/// 圓形漸層背景 + 大眼睛 + Emoji 表情
/// 動畫過渡不同情緒

import 'package:flutter/material.dart';
import '../models/deskmate_state.dart';

class TinaFaceWidget extends StatelessWidget {
  final TinaFace face;
  final double size;
  final VoidCallback? onTap;

  const TinaFaceWidget({
    super.key,
    required this.face,
    this.size = 200,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = tinaFaceEmoji[face] ?? '😊';
    final color = Color(tinaFaceColor[face] ?? 0xFF6C63FF);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.7),
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外圈光暈 (always rotating)
            _buildOuterGlow(color),
            // 內圈
            Container(
              width: size * 0.75,
              height: size * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            // 眼睛
            Positioned(
              top: size * 0.25,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEye(color),
                  SizedBox(width: size * 0.2),
                  _buildEye(color),
                ],
              ),
            ),
            // Emoji 嘴巴/表情
            Positioned(
              bottom: size * 0.18,
              child: AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: size * 0.2,
                ),
                child: Text(emoji),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEye(Color color) {
    return Container(
      width: size * 0.12,
      height: size * 0.12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.06,
          height: size * 0.06,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildOuterGlow(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 360),
      duration: Duration(seconds: 8),
      builder: (context, angle, child) {
        return Transform.rotate(
          angle: angle * 3.14159 / 180,
          child: child,
        );
      },
      child: Container(
        width: size * 0.9,
        height: size * 0.9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
    );
  }
}
