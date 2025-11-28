import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// 在后台 isolate 中执行图片网格拼接，避免阻塞 UI。
///
/// 通常业务层使用这个方法即可。
Future<String> mergeImagesGridToFileInIsolate(
    List<String> imagePaths, {
      int targetWidth = 1500,
      int padding = 4,
      int bgR = 255,
      int bgG = 255,
      int bgB = 255,
    }) {
  // compute 要求参数可跨 isolate 传递，这里用 Map 封装
  final payload = <String, dynamic>{
    'paths': imagePaths,
    'targetWidth': targetWidth,
    'padding': padding,
    'bgR': bgR,
    'bgG': bgG,
    'bgB': bgB,
  };

  return compute<Map<String, dynamic>, String>(
    _mergeImagesGridToFileIsolate,
    payload,
  );
}

/// 同步版本（在当前 isolate 中执行）
///
/// 一般不用它，除非你在非 UI isolate 中手动调用。
Future<String> mergeImagesGridToFile(
    List<String> imagePaths, {
      int targetWidth = 1500,
      int padding = 4,
      int bgR = 255,
      int bgG = 255,
      int bgB = 255,
    }) async {
  return _mergeImagesGridToFileCore(
    imagePaths,
    targetWidth: targetWidth,
    padding: padding,
    bgR: bgR,
    bgG: bgG,
    bgB: bgB,
  );
}

/// compute 的入口函数（必须是顶层 / 静态方法），在后台 isolate 中执行。
String _mergeImagesGridToFileIsolate(
    Map<String, dynamic> payload,
    ) {
  final List<String> imagePaths =
  (payload['paths'] as List).cast<String>();
  final int targetWidth = payload['targetWidth'] as int;
  final int padding = payload['padding'] as int;
  final int bgR = payload['bgR'] as int;
  final int bgG = payload['bgG'] as int;
  final int bgB = payload['bgB'] as int;

  return _mergeImagesGridToFileCore(
    imagePaths,
    targetWidth: targetWidth,
    padding: padding,
    bgR: bgR,
    bgG: bgG,
    bgB: bgB,
  );
}

/// 核心拼接算法（同步），
/// 在后台 isolate 或当前 isolate 中调用均可。
String _mergeImagesGridToFileCore(
    List<String> imagePaths, {
      required int targetWidth,
      required int padding,
      required int bgR,
      required int bgG,
      required int bgB,
    }) {
  if (imagePaths.isEmpty) {
    throw ArgumentError('imagePaths 不能为空');
  }

  // 同步 IO：反正跑在后台 isolate，不会卡 UI
  final List<img.Image> images = [];
  for (final path in imagePaths) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }

    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      images.add(decoded);
    }
  }

  if (images.isEmpty) {
    throw StateError('无法解码任何图片，请检查图片路径或格式是否正确');
  }

  final int n = images.length;

  // cols = ceil(sqrt(n)), rows = ceil(n / cols)
  final int cols = sqrt(n).ceil();
  final int rows = (n / cols).ceil();

  // 按行分组
  final List<List<img.Image>> groups = [];
  int idx = 0;
  for (int r = 0; r < rows; r++) {
    final int remain = n - idx;
    final int count = min(cols, remain);
    groups.add(images.sublist(idx, idx + count));
    idx += count;
  }

  final img.ColorRgb8 bgColor = img.ColorRgb8(bgR, bgG, bgB);

  final List<img.Image> rowCanvases = [];
  int totalHeight = 0;

  // 一行一行处理
  for (final rowImages in groups) {
    // 每张图片的宽高比
    final List<double> ratios = rowImages
        .map((im) => im.width / im.height)
        .toList(growable: false);

    final double totalRatio =
    ratios.fold<double>(0, (prev, r) => prev + r);

    // 根据 targetWidth 推算行高
    int rowHeight = (targetWidth / totalRatio).floor();
    if (rowHeight <= 0) rowHeight = 1;

    // 缩放到统一高度 rowHeight
    final List<img.Image> scaledRow = [];
    for (int i = 0; i < rowImages.length; i++) {
      final img.Image im = rowImages[i];
      final double ratio = ratios[i];

      int newWidth = (rowHeight * ratio).floor();
      if (newWidth <= 0) newWidth = 1;

      final img.Image resized = img.copyResize(
        im,
        width: newWidth,
        height: rowHeight,
      );
      scaledRow.add(resized);
    }

    // 行宽 = 所有图片宽度 + 间距
    final int rowWidth = scaledRow.fold<int>(
      0,
          (prev, im) => prev + im.width,
    ) +
        padding * (scaledRow.length - 1);

    // 行画布
    final img.Image rowCanvas = img.Image(
      width: rowWidth,
      height: rowHeight,
      backgroundColor: bgColor,
    );

    int x = 0;
    for (final im in scaledRow) {
      img.compositeImage(
        rowCanvas,
        im,
        dstX: x,
        dstY: 0,
      );
      x += im.width + padding;
    }

    rowCanvases.add(rowCanvas);
    totalHeight += rowHeight + padding;
  }

  // 去掉最后一行多加的 padding
  totalHeight -= padding;
  if (totalHeight <= 0) totalHeight = 1;

  // 最终大画布
  final img.Image canvas = img.Image(
    width: targetWidth,
    height: totalHeight,
    backgroundColor: bgColor,
  );

  int y = 0;
  for (img.Image row in rowCanvases) {
    if (row.width > targetWidth) {
      row = img.copyResize(
        row,
        width: targetWidth,
        height: row.height,
      );
    }

    final int rowWidth = row.width;
    final int offsetX = ((targetWidth - rowWidth) / 2).floor();

    img.compositeImage(
      canvas,
      row,
      dstX: offsetX,
      dstY: y,
    );

    y += row.height + padding;
  }

  // 输出文件：放在第一张图片同目录
  final String firstPath = imagePaths.first;
  final Directory parentDir = File(firstPath).parent;
  final String outputPath =
      '${parentDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.jpg';

  final List<int> jpgBytes = img.encodeJpg(
    canvas,
    quality: 90,
  );
  final outputFile = File(outputPath);
  outputFile.writeAsBytesSync(jpgBytes, flush: true);

  return outputPath;
}
