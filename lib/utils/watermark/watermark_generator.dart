// lib/utils/watermark/watermark_generator.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'encryption.dart';

/// 为单张图片生成水印（右下角二维码）
///
/// :param inputFile: 原始图片 File
/// :param name: 用户姓名
/// :param userNumber: 工号（字符串形式）
/// :param datetime: 基准时间
/// :param minuteOffset: 在基准时间上的偏移分钟数
/// :returns: 生成后的水印图片本地路径
Future<String> generateWatermarkForImage({
  required File inputFile,
  required String name,
  required String userNumber,
  required DateTime datetime,
  int minuteOffset = 0,
}) async {
  // 生成时间戳（秒）
  final int timestamp =
      datetime.add(Duration(minutes: minuteOffset)).millisecondsSinceEpoch ~/
      1000;

  // 组装加密数据
  final Map<String, dynamic> payload = createWatermarkData(
    timestamp: timestamp,
    s: int.parse(userNumber),
    n: name,
  );
  final String encrypted = encryptWatermark(payload);

  final String qrPayload = jsonEncode(<String, dynamic>{
    'text': encrypted,
    'version': 'v1.0',
  });

  // 读取原图
  final Uint8List inputBytes = await inputFile.readAsBytes();
  final img.Image? original = img.decodeImage(inputBytes);
  if (original == null) {
    throw Exception('无法解析原始图片');
  }

  // 直接拉伸适配到 1080x1920（简单粗暴，后面你要的话再做等比裁剪）
  const int canvasWidth = 1080;
  const int canvasHeight = 1920;

  final img.Image resized = img.copyResize(
    original,
    width: canvasWidth,
    height: canvasHeight,
    interpolation: img.Interpolation.linear,
  );

  // 生成二维码图
  final img.Image qrImage = await _generateQrImage(qrPayload, 260);
  final int qrW = qrImage.width;
  final int qrH = qrImage.height;

  // 计算右下角位置
  final int dstX = canvasWidth - qrW;
  final int dstY = canvasHeight - qrH;

  // compositeImage 是 4.x 版本里用来贴图的函数
  img.compositeImage(
    resized, // dst
    qrImage, // src
    dstX: dstX,
    dstY: dstY,
  );

  // 输出到临时目录
  final Directory dir = await getTemporaryDirectory();
  final String outputPath =
      '${dir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg';

  final List<int> jpgBytes = img.encodeJpg(resized, quality: 85);
  await File(outputPath).writeAsBytes(jpgBytes);

  return outputPath;
}

/// 生成带白色背景和留白边距的二维码，返回 image.Image
Future<img.Image> _generateQrImage(String text, int size) async {
  const double padding = 10.0; // 四周留白
  final double totalSize = size + padding * 2; // 画布总尺寸

  // 录制绘制过程
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);

  // 白色背景
  final Paint whitePaint = Paint()..color = Colors.white;
  final Rect fullRect = Rect.fromLTWH(0, 0, totalSize, totalSize);
  canvas.drawRect(fullRect, whitePaint);

  // 创建 QrPainter（黑码）
  final QrPainter painter = QrPainter(
    data: text,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
    gapless: true,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Colors.black,
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
  );

  // 移动画布，让二维码绘制在中心区域内，四周留白 padding
  canvas.save();
  canvas.translate(padding, padding);
  painter.paint(
    canvas,
    Size(size.toDouble(), size.toDouble()), // 这里必须是 Size，而不是 Rect
  );
  canvas.restore();

  // 结束录制，生成 ui.Image
  final ui.Image qrUiImage = await recorder.endRecording().toImage(
    totalSize.toInt(),
    totalSize.toInt(),
  );

  // 转 ByteData
  final ByteData? byteData =
  await qrUiImage.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw Exception("二维码绘制失败：ByteData 为空");
  }

  // ByteData -> Uint8List -> image.Image
  final Uint8List buffer = byteData.buffer.asUint8List();
  final img.Image? result = img.decodeImage(buffer);
  if (result == null) {
    throw Exception("二维码解码失败");
  }
  return result;
}