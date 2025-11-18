import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;

class GlobalLoading {
  static final GlobalLoading _instance = GlobalLoading._internal();
  factory GlobalLoading() => _instance;
  GlobalLoading._internal();

  OverlayEntry? _overlayEntry;
  bool _isShowing = false;
  _FullScreenLoadingState? _loadingState;

  /// 显示全局 Loading
  void show(BuildContext context, {String text = "加载中..."}) {
    if (_isShowing) return; // 避免重复创建

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return _FullScreenLoading(
          initialText: text,
          onInit: (state) {
            _loadingState = state;
          },
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    _isShowing = true;
  }

  /// 更新 loading 的文字
  void update(String text) {
    if (_isShowing && _loadingState != null) {
      _loadingState!.updateText(text);
    }
  }

  /// 隐藏全局 Loading
  void hide() {
    if (!_isShowing) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _loadingState = null;
    _isShowing = false;
  }

  bool get isShowing => _isShowing;
}

class _FullScreenLoading extends StatefulWidget {
  final String initialText;
  final void Function(_FullScreenLoadingState state) onInit;

  const _FullScreenLoading({
    required this.initialText,
    required this.onInit,
  });

  @override
  _FullScreenLoadingState createState() => _FullScreenLoadingState();
}

class _FullScreenLoadingState extends State<_FullScreenLoading> {
  late String text;

  @override
  void initState() {
    super.initState();
    text = widget.initialText;
    widget.onInit(this); // 绑定到 GlobalLoading
  }

  void updateText(String newText) {
    setState(() {
      text = newText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer( // 禁止交互
      absorbing: true,
      child: Container(
        color: ui.Color.fromRGBO(0, 0, 0, 0.5), // 背景遮罩
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
