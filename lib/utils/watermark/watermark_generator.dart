import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'encryption.dart';
import 'watermark_painter.dart';

/// 为单张图片生成水印（右下角二维码 + 左下文字）
///
/// :param inputFile: 原始图片 File
/// :param name: 用户姓名
/// :param userNumber: 工号（字符串形式）
/// :param datetime: 基准时间
/// :param minuteOffset: 在基准时间上的偏移分钟数
/// :param location: 位置信息
/// :returns: 生成后的水印图片本地路径
Future<String> generateWatermarkForImage({
  required File inputFile,
  required String name,
  required String userNumber,
  required DateTime datetime,
  int minuteOffset = 0,
  String location = 'Q南宁中国锦园',
}) async {
  // 1. 计算偏移后的时间（用于文字显示、时间戳）
  final DateTime effectiveTime = datetime.add(Duration(minutes: minuteOffset));
  final int timestamp = effectiveTime.millisecondsSinceEpoch ~/ 1000;

  // 2. 组装加密数据（保持和原来 Python/后端一致）
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

  // 3. 解码原图为 ui.Image
  final Uint8List inputBytes = await inputFile.readAsBytes();
  final ui.Image originalImage = await _decodeUiImage(inputBytes);

  // 4. 生成二维码 ui.Image
  final ui.Image qrImage = await _generateQrImage(qrPayload, 260);

  // 5. 用 Canvas 合成水印图
  final ui.Image watermarkedImage = await renderWatermarkedImage(
    originalImage: originalImage,
    qrImage: qrImage,
    name: name,
    datetime: effectiveTime,
    location: location,
  );

  // 6. 导出 PNG 文件
  final ByteData? pngData =
  await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);
  if (pngData == null) {
    throw Exception("导出水印图片失败：ByteData为空");
  }

  final Directory tmpDir = await getTemporaryDirectory();
  final String outputPath =
      '${tmpDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.png';

  await File(outputPath).writeAsBytes(pngData.buffer.asUint8List());
  return outputPath;
}

/// 将 Uint8List 解码为 ui.Image
Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

/// 根据二维码内容生成 ui.Image
Future<ui.Image> _generateQrImage(String text, int size) async {
  const double padding = 10.0;
  final double totalSize = size + padding * 2;

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);

  // 白色背景
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, totalSize, totalSize),
    ui.Paint()..color = Colors.white,
  );

  // 创建 QrPainter
  final QrPainter painter = QrPainter(
    data: text,
    version: QrVersions.auto,
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

  // 绘制二维码到中间（留 padding）
  canvas.save();
  canvas.translate(padding, padding);
  painter.paint(
    canvas,
    Size(size.toDouble(), size.toDouble()),
  );
  canvas.restore();

  final ui.Image qrUiImage = await recorder.endRecording().toImage(
    totalSize.toInt(),
    totalSize.toInt(),
  );
  return qrUiImage;
}
