import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 使用 Canvas 绘制带文字和二维码的水印图
///
/// - 自动裁切为 9:16 并拉伸到 1080x1920
/// - 左下角文字水印（时间 / 姓名 / 日期 / 位置）
/// - 右下角二维码
/// - 位置图标：assets/icons/location_icon.png
Future<ui.Image> renderWatermarkedImage({
  required ui.Image originalImage,
  required ui.Image qrImage,
  required String name,
  required DateTime datetime,
  required String location,
}) async {
  const int canvasWidth = 1080;
  const int canvasHeight = 1920;
  const double targetRatio = canvasWidth / canvasHeight; // 9/16

  // 先保证是竖图：横图旋转 90°
  final ui.Image srcImage = await _ensurePortrait(originalImage);

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);

  // 背景先填黑，避免透明边
  final ui.Paint bgPaint = ui.Paint()..color = Colors.black;
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
    bgPaint,
  );

  // 自动裁切 9:16
  final double imgRatio = srcImage.width / srcImage.height;
  late ui.Rect srcRect;

  if (imgRatio > targetRatio) {
    // 图过宽 → 裁左右
    final double newWidth = srcImage.height * targetRatio;
    final double xOffset = (srcImage.width - newWidth) / 2;
    srcRect = ui.Rect.fromLTWH(
      xOffset,
      0,
      newWidth,
      srcImage.height.toDouble(),
    );
  } else {
    // 图过高 → 裁上下
    final double newHeight = srcImage.width / targetRatio;
    final double yOffset = (srcImage.height - newHeight) / 2;
    srcRect = ui.Rect.fromLTWH(
      0,
      yOffset,
      srcImage.width.toDouble(),
      newHeight,
    );
  }

  // 将裁切后的区域拉伸铺满 1080x1920
  final ui.Rect dstRect = ui.Rect.fromLTWH(
    0,
    0,
    canvasWidth.toDouble(),
    canvasHeight.toDouble(),
  );
  canvas.drawImageRect(srcImage, srcRect, dstRect, ui.Paint());

  // 绘制左下文字区域（包含位置图标）
  await _drawTextOverlay(
    canvas: canvas,
    name: name,
    datetime: datetime,
    location: location,
  );

  // 绘制右下角二维码
  final double qrX = canvasWidth - qrImage.width.toDouble();
  final double qrY = canvasHeight - qrImage.height.toDouble();
  canvas.drawImage(qrImage, ui.Offset(qrX, qrY), ui.Paint());

  // 输出最终图片
  final ui.Image outImage = await recorder.endRecording().toImage(
    canvasWidth,
    canvasHeight,
  );
  return outImage;
}

/// 如果是横图则旋转 90°，返回竖直方向的 ui.Image
Future<ui.Image> _ensurePortrait(ui.Image image) async {
  if (image.width <= image.height) {
    return image;
  }

  // 横图 → 旋转 90°
  final int newWidth = image.height;
  final int newHeight = image.width;

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);

  // 旋转 90 度：先平移，再旋转
  canvas.translate(newWidth.toDouble(), 0);
  canvas.rotate(math.pi / 2);

  canvas.drawImage(image, ui.Offset.zero, ui.Paint());

  final ui.Image rotated = await recorder.endRecording().toImage(
    newWidth,
    newHeight,
  );
  return rotated;
}

/// 绘制左下角文字水印 + 位置图标
Future<void> _drawTextOverlay({
  required ui.Canvas canvas,
  required String name,
  required DateTime datetime,
  required String location,
}) async {
  // 时间/日期
  final String timeText =
      '${datetime.hour.toString().padLeft(2, '0')}:${datetime.minute.toString().padLeft(2, '0')}';
  final String dateText =
      '${datetime.year}-${datetime.month.toString().padLeft(2, '0')}-${datetime.day.toString().padLeft(2, '0')}';
  final String weekText = _weekdayCn(datetime.weekday);

  // 颜色
  final ui.Color textColor = Colors.white;
  final ui.Paint panelPaint = ui.Paint()..color = ui.Color.fromRGBO(0, 0, 0, 0.3);

  // ------------- 第一行背景（时间 + 姓名 + 日期）-------------
  const double firstX = 27;
  const double firstY = 1674;
  const double firstW = 480;
  const double firstH = 107;
  const double radius = 15;

  final ui.RRect firstPanel = ui.RRect.fromRectAndRadius(
    ui.Rect.fromLTWH(firstX, firstY, firstW, firstH),
    const ui.Radius.circular(radius),
  );
  canvas.drawRRect(firstPanel, panelPaint);

  // 时间
  _drawText(
    canvas,
    text: timeText,
    fontSize: 75,
    color: textColor,
    offset: const ui.Offset(firstX + 15, firstY - 4),
  );

  // 姓名
  _drawText(
    canvas,
    text: name,
    fontSize: 34,
    color: textColor,
    offset: const ui.Offset(firstX + 220, firstY + 5),
  );

  // 日期 + 星期
  _drawText(
    canvas,
    text: '$dateText $weekText',
    fontSize: 32,
    color: textColor,
    offset: const ui.Offset(firstX + 220, firstY + 50),
  );

  // ------------- 第二行背景（位置 + 图标）-------------
  const double locX = 27;
  const double locY = 1794;
  const double locW = 302;
  const double locH = 60;

  final ui.RRect secondPanel = ui.RRect.fromRectAndRadius(
    ui.Rect.fromLTWH(locX, locY, locW, locH),
    const ui.Radius.circular(radius),
  );
  canvas.drawRRect(secondPanel, panelPaint);

  // 加载位置图标
  final ui.Image locationIcon = await _loadAssetImage(
    'assets/icons/location_icon.png',
  );

  const double iconSize = 30;
  canvas.drawImageRect(
    locationIcon,
    ui.Rect.fromLTWH(
      0,
      0,
      locationIcon.width.toDouble(),
      locationIcon.height.toDouble(),
    ),
    ui.Rect.fromLTWH(locX + 22, locY + 14, iconSize, iconSize),
    ui.Paint(),
  );

  // 位置文字（留出图标空间）
  _drawText(
    canvas,
    text: location,
    fontSize: 32,
    color: textColor,
    offset: const ui.Offset(locX + 65, locY + 5),
  );
}

/// 低层级文字绘制封装：使用 Paragraph + fontFamily
///
/// 注意：fontFamily 必须在 pubspec.yaml 里声明：
///
/// flutter:
///   fonts:
///     - family: Siyuan
///       fonts:
///         - asset: assets/fonts/siyuansongti.ttf
void _drawText(
  ui.Canvas canvas, {
  required String text,
  required double fontSize,
  required ui.Color color,
  required ui.Offset offset,
}) {
  const String fontFamily = 'Siyuan'; // 和 pubspec.yaml 中的 family 一致

  final ui.ParagraphBuilder builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
          ),
        )
        ..pushStyle(
          ui.TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: fontFamily,
          ),
        )
        ..addText(text);

  final ui.Paragraph paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: double.infinity));

  canvas.drawParagraph(paragraph, offset);
}

/// 从 assets 加载 PNG 图片为 ui.Image
Future<ui.Image> _loadAssetImage(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);
  final Uint8List bytes = data.buffer.asUint8List();
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

/// 星期数字转中文
String _weekdayCn(int weekday) {
  const List<String> weeks = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return weeks[weekday - 1];
}
