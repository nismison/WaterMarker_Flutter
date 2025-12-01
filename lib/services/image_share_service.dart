import 'package:flutter/foundation.dart';
import 'package:share_handler/share_handler.dart';

/// 专门从 SharedMedia 中抽取图片路径的工具类。
///
/// 不负责导航、不负责其他业务，只负责把 SharedMedia -> List<String> paths。
class ImageShareService {
  /// 从 SharedMedia 中抽取本地文件路径列表。
  ///
  /// - 只保留非 null 且非空字符串的 path；
  /// - 当前假定 attachments 都是图片（因为 Manifest 中限定了 image/*）。
  List<String> extractPaths(SharedMedia media) {
    final attachments = media.attachments;
    if (attachments == null || attachments.isEmpty) {
      debugPrint('[ImageShareService] attachments is empty');
      return const [];
    }

    final paths = attachments
        .map((e) => e?.path)
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toList();

    debugPrint('[ImageShareService] paths: $paths');
    return paths;
  }
}
