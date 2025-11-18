import 'package:flutter/material.dart';
import '../pages/select_images_page.dart';

/// 打开图片选择器，返回用户选择的文件路径列表
///
/// :param context: 传入 BuildContext
/// :param maxSelection: 最多选择的图片数
/// :param preSelectedPaths: 打开页面时默认选中的图片
/// :returns: 如果用户按“确定”选择了图片，返回 List<String>；如果按返回键或取消，返回 null
Future<List<String>?> showImagePicker(
    BuildContext context, {
      int maxSelection = 9,
      List<String> preSelectedPaths = const [],
    }) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SelectImagesPage(
        maxSelection: maxSelection,
        preSelectedPaths: preSelectedPaths,
      ),
    ),
  );

  return result as List<String>?; // null 代表取消选择
}
