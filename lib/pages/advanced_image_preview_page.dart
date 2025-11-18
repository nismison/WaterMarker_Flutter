import 'dart:io';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 对外统一调用方法：
/// - 只传 imagePath：单图预览，支持下滑关闭
/// - 传 imageList + imagePath：可左右滑动 + 下滑关闭
Future<void> showImagePreview(
    BuildContext context, {
      String? imagePath,
      List<String>? imageList,
      bool useHero = false,
      Duration fadeDuration = const Duration(milliseconds: 150),
    }) async {
  if (imageList == null && imagePath == null) {
    throw ArgumentError('必须提供 imagePath 或 imageList');
  }

  int initialIndex = 0;
  if (imageList != null && imagePath != null) {
    final idx = imageList.indexOf(imagePath);
    if (idx >= 0) {
      initialIndex = idx;
    }
  }

  await Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, _, _) => AdvancedImagePreviewPage(
        imageList: imageList,
        imagePath: imagePath,
        initialIndex: initialIndex,
        useHero: useHero,
      ),
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: fadeDuration,
    ),
  );
}

class AdvancedImagePreviewPage extends StatefulWidget {
  final List<String>? imageList;
  final String? imagePath;
  final int initialIndex;
  final bool useHero;

  const AdvancedImagePreviewPage({
    super.key,
    this.imageList,
    this.imagePath,
    this.initialIndex = 0,
    this.useHero = false,
  });

  @override
  State<AdvancedImagePreviewPage> createState() =>
      _AdvancedImagePreviewPageState();
}

class _AdvancedImagePreviewPageState extends State<AdvancedImagePreviewPage>
    with SingleTickerProviderStateMixin {
  late final ExtendedPageController _pageController;
  late int _currentIndex;

  // 双击缩放动画
  late final AnimationController _doubleTapAnimationController;
  Animation<double>? _doubleTapAnimation;
  VoidCallback? _doubleTapAnimationListener;
  final List<double> _doubleTapScales = <double>[1.0, 2.0];

  @override
  void initState() {
    super.initState();
    _enterFullScreen();

    final List<String> images = widget.imageList ?? <String>[widget.imagePath!];
    final int safeIndex = (widget.initialIndex >= 0 &&
        widget.initialIndex < images.length)
        ? widget.initialIndex
        : 0;

    _currentIndex = safeIndex;
    _pageController = ExtendedPageController(initialPage: safeIndex);

    _doubleTapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _exitFullScreen();
    _pageController.dispose();
    _doubleTapAnimation?.removeListener(_doubleTapAnimationListener ?? () {});
    _doubleTapAnimationController.dispose();
    super.dispose();
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.imageList ?? <String>[widget.imagePath!];

    return ExtendedImageSlidePage(
      slideAxis: SlideAxis.vertical,
      slideType: SlideType.onlyImage,
      resetPageDuration: const Duration(milliseconds: 200),
      slidePageBackgroundHandler: (Offset offset, Size pageSize) {
        final double dy = offset.dy.abs();
        final double h = pageSize.height;
        final double opacity = (1.0 - dy / (h * 0.7)).clamp(0.0, 1.0);
        return ui.Color.fromRGBO(0, 0, 0, opacity);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            ExtendedImageGesturePageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (int index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (BuildContext context, int index) {
                final String path = images[index];
                return _buildPreviewItem(path);
              },
            ),

            // 顶部关闭按钮
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),

            // 底部页码
            if (images.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Text(
                  '${_currentIndex + 1} / ${images.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String path) {
    return ExtendedImage.file(
      File(path),
      fit: BoxFit.contain,
      mode: ExtendedImageMode.gesture,
      enableSlideOutPage: true,
      initGestureConfigHandler: (ExtendedImageState state) {
        return GestureConfig(
          inPageView: true,
          initialScale: 1.0,
          minScale: 1.0,
          maxScale: 3.0,
          animationMinScale: 1.0,
          animationMaxScale: 3.0,
          speed: 1.0,
          inertialSpeed: 100.0,
          cacheGesture: false,
        );
      },
      onDoubleTap: _onImageDoubleTap,
      heroBuilderForSlidingPage: widget.useHero
          ? (Widget result) => Hero(tag: path, child: result)
          : null,
    );
  }

  /// 双击缩放：基于官方 demo 的实现，加上 null-safety
  void _onImageDoubleTap(ExtendedImageGestureState state) {
    // 没有指针位置就不处理
    final Offset? pointerDownPosition = state.pointerDownPosition;
    if (pointerDownPosition == null) {
      return;
    }

    final double? begin = state.gestureDetails?.totalScale;
    double end;

    // 移除旧监听
    _doubleTapAnimation?.removeListener(_doubleTapAnimationListener ?? () {});
    // 停止上一次动画
    _doubleTapAnimationController.stop();
    _doubleTapAnimationController.reset();

    if (begin == _doubleTapScales[0]) {
      end = _doubleTapScales[1];
    } else {
      end = _doubleTapScales[0];
    }

    _doubleTapAnimationListener = () {
      final double scale = _doubleTapAnimation!.value;
      state.handleDoubleTap(
        scale: scale,
        doubleTapPosition: pointerDownPosition,
      );
    };

    _doubleTapAnimation = _doubleTapAnimationController.drive(
      Tween<double>(begin: begin, end: end),
    );
    _doubleTapAnimation!.addListener(_doubleTapAnimationListener!);

    _doubleTapAnimationController.forward();
  }
}
