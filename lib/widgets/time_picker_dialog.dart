import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// @description 时间选择弹窗：基于 Forui FPicker 的小时-分钟滚轮选择器，选中项高亮半透明蓝色背景
///
/// @param context 上下文
/// @param initialTime 初始时间
/// @param onSelected 选择完成后的回调
void showTimePickerDialog({
  required BuildContext context,
  required TimeOfDay initialTime,
  required ValueChanged<TimeOfDay> onSelected,
}) {
  // 可选值范围
  final List<int> hours = List.generate(24, (i) => i); // 0-23
  final List<int> minutes = List.generate(60, (i) => i); // 0-59

  // 初始下标
  int hourIndex = initialTime.hour.clamp(0, hours.length - 1);
  int minuteIndex = initialTime.minute.clamp(0, minutes.length - 1);

  // 状态值
  int selectedHour = hours[hourIndex];
  int selectedMinute = minutes[minuteIndex];

  // 控制器：两列滚轮
  final FPickerController controller = FPickerController(
    initialIndexes: [hourIndex, minuteIndex],
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
                    onSelected(
                      TimeOfDay(hour: selectedHour, minute: selectedMinute),
                    );
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
                    color: Colors.transparent, // 完全透明颜色，效果等同于无边框
                    width: 0.0001, // 宽度不能 = 0，必须大于 0
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
                  // indexes: [hourIndex, minuteIndex]
                  selectedHour = hours[indexes[0]];
                  selectedMinute = minutes[indexes[1]];
                },
                children: [
                  // 小时选择列
                  FPickerWheel(
                    flex: 1,
                    loop: false,
                    itemExtent: 36,
                    children: hours
                        .map(
                          (h) =>
                              Center(child: Text(h.toString().padLeft(2, '0'))),
                        )
                        .toList(),
                  ),

                  // 分钟选择列
                  FPickerWheel(
                    flex: 1,
                    loop: false,
                    itemExtent: 36,
                    children: minutes
                        .map(
                          (m) =>
                              Center(child: Text(m.toString().padLeft(2, '0'))),
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
