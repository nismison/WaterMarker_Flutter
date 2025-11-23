import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/user_info_model.dart';

/// @description 用户选择弹窗（单列滚轮，基于 List<Map> 数据源）
///
/// @param context 上下文
/// @param userList 用户列表（list item 格式为：{'name': '张三', 'number': '001'}）
/// @param initialName 初始选中的 name
/// @param onSelected 回调选中的用户对象
void showUserPickerDialog({
  required BuildContext context,
  required List<UserInfoModel> userList,
  required String initialName,
  required void Function(UserInfoModel) onSelected,
}) {
  if (userList.isEmpty) {
    // 给个 fallback，避免滚轮空数组导致 UI 崩
    userList = [
      UserInfoModel.fromJson(jsonDecode('{"name": "无用户", "number": null}')),
    ];
  }

  // 初始位置
  int initialIndex = userList.indexWhere((u) => u.name == initialName);
  if (initialIndex < 0) initialIndex = 0;

  // 当前临时选中值
  UserInfoModel selectedUser = userList[initialIndex];

  // 两列滚轮控制器
  final FPickerController controller = FPickerController(
    initialIndexes: [initialIndex],
  );

  showFSheet(
    context: context,
    side: FLayout.btt,
    builder: (_) {
      return Container(
        height: 280,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSelected(selectedUser);
                  },
                  child: Text(
                    '确定',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: FPicker(
                controller: controller,
                style: FPickerStyle(
                  focusedOutlineStyle: FFocusedOutlineStyle(
                    color: Colors.transparent,
                    width: 0.0001,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  selectionBorderRadius: BorderRadius.circular(8),
                  selectionHeightAdjustment: 20,
                  selectionColor: const Color.fromARGB(
                    30,
                    33,
                    150,
                    243,
                  ), // 选中区域半透明蓝色
                ).call,
                onChange: (indexes) {
                  selectedUser = userList[indexes[0]];
                },
                children: [
                  FPickerWheel(
                    flex: 1,
                    loop: false,
                    itemExtent: 36,
                    children: userList
                        .map(
                          (u) => Center(
                            child: Text(
                              u.name ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
