// lib/widgets/sliding_bottom_nav_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// 底部导航每个 item 的配置
class SlidingNavBarItem {
  const SlidingNavBarItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

/// iOS dock 风格 + 胶囊滑块 + 毛玻璃
class SlidingBottomNavBar extends StatelessWidget {
  const SlidingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChange,
    required this.items,
  }) : assert(items.length >= 2, '需要至少两个导航项');

  final int currentIndex;
  final ValueChanged<int> onChange;
  final List<SlidingNavBarItem> items;

  // ====== 配色（稍微“实”一点，在白背景上更清晰） ======
  // 整个 dock 背景：浅灰 + 白玻璃
  static const Color _dockBackgroundColor =
  Color(0xD9E5E7EB); // ~85% 不透明的浅灰

  // 胶囊：纯白半透明，比背景更亮一点
  static const Color _capsuleColor = Color(0xF2FFFFFF); // ~95% 不透明的白

  // 描边：略带蓝的浅灰边
  static final Color _dockBorderColor = Color.fromRGBO(255, 255, 255, 0.35); // 边缘更亮一点

  // 图标和文字颜色（深浅对比）
  static const Color _iconColorSelected = Color(0xFF111827); // 非常深的灰
  static const Color _iconColorUnselected = Color(0xFF6B7280); // 中灰

  static const Color _textColorSelected = Color(0xFF111827);
  static const Color _textColorUnselected = Color(0xFF6B7280);

  // 阴影稍弱一点，避免太“沉”
  static const Color _shadowColor = Colors.black26;

  // 毛玻璃：略弱，比深色版更轻一点
  static const double _dockBlurSigma = 14.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        // 让 dock 左右有点空隙，更像一块悬浮的板
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _dockBlurSigma,
              sigmaY: _dockBlurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _dockBackgroundColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _dockBorderColor,
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: _shadowColor,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double itemWidth = constraints.maxWidth / items.length;

                  // 整个 nav 区域固定高度，内部元素在这个高度内做动画
                  return SizedBox(
                    height: 60,
                    child: Stack(
                      children: [
                        // ======= 背景胶囊指示器（淡白色 + 轻微高亮） =======
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 130),
                          curve: Curves.easeOutCubic,
                          left: currentIndex * itemWidth,
                          width: itemWidth,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            child: Container(
                              height: 54,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _capsuleColor,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color:
                                  Colors.white.withOpacity(0.35), // 边缘更亮一点
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ======= 前景：图标 + 文本 =======
                        Row(
                          children: List.generate(items.length, (index) {
                            final item = items[index];
                            final bool selected = index == currentIndex;

                            final Color iconColor = selected
                                ? _iconColorSelected
                                : _iconColorUnselected;

                            final Color textColor = selected
                                ? _textColorSelected
                                : _textColorUnselected;

                            return SizedBox(
                              width: itemWidth,
                              height: 60, // 每个 item 固定高度，避免跳动
                              child: _SlidingNavBarItemWidget(
                                item: item,
                                selected: selected,
                                iconColor: iconColor,
                                textColor: textColor,
                                onTap: () => onChange(index),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlidingNavBarItemWidget extends StatefulWidget {
  const _SlidingNavBarItemWidget({
    required this.item,
    required this.selected,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  final SlidingNavBarItem item;
  final bool selected;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  State<_SlidingNavBarItemWidget> createState() =>
      _SlidingNavBarItemWidgetState();
}

class _SlidingNavBarItemWidgetState extends State<_SlidingNavBarItemWidget> {
  double _pressScale = 1.0;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _pressScale = 0.96; // 微缩一点，当做按压反馈
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _pressScale = 1.0;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _pressScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 150);

    // 选中时略放大一点，按下时略缩小一点，两者叠加
    final double baseScale = widget.selected ? 1.03 : 1.0;
    final double targetScale = baseScale * _pressScale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: Center(
        // 确保在固定高度内居中，缩放不会改变整体高度
        child: AnimatedScale(
          scale: targetScale,
          duration: duration,
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOut,
                child: Icon(
                  widget.item.icon,
                  size: widget.selected ? 26 : 24,
                  color: widget.iconColor,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: duration,
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                  widget.selected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.textColor,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
