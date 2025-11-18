import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// @description 日期选择弹窗：多列年/月/日滚轮选择，选中项有高亮背景
///
/// @param context 上下文
/// @param initialDate 初始日期
/// @param onSelected 选择完成回调
void showDatePickerDialog({
  required BuildContext context,
  required DateTime initialDate,
  required ValueChanged<DateTime> onSelected,
}) {
  final now = DateTime.now();

  // 年：当前年起，往后 3 年（共 4 年）
  final List<int> years = List.generate(4, (i) => now.year + i);
  // 月：1 - 12
  final List<int> months = List.generate(12, (i) => i + 1);
  // 日：固定 1 - 31，真正生成日期时再按当月实际天数裁剪
  final List<int> days = List.generate(31, (i) => i + 1);

  int yearIndex = years.indexOf(initialDate.year);
  if (yearIndex < 0) yearIndex = 0;

  int monthIndex = (initialDate.month - 1).clamp(0, months.length - 1);
  int dayIndex = (initialDate.day - 1).clamp(0, days.length - 1);

  final FPickerController controller = FPickerController(
    initialIndexes: <int>[yearIndex, monthIndex, dayIndex],
  );

  int selectedYear = years[yearIndex];
  int selectedMonth = months[monthIndex];
  int selectedDay = days[dayIndex];

  showFSheet(
    context: context,
    side: FLayout.btt,
    builder: (_) {
      return Container(
        height: 320,
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
                    // 根据选中的年/月，计算该月的实际天数
                    final int maxDay = DateTime(
                      selectedYear,
                      selectedMonth + 1,
                      0,
                    ).day;
                    final int finalDay = selectedDay > maxDay
                        ? maxDay
                        : selectedDay;

                    Navigator.pop(context);
                    onSelected(DateTime(selectedYear, selectedMonth, finalDay));
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
                    width: 0.0001, // 宽度不能为 0，给一个极小的值即可绕过断言
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
                onChange: (List<int> indexes) {
                  // indexes 顺序：年 / 月 / 日
                  selectedYear = years[indexes[0]];
                  selectedMonth = months[indexes[1]];
                  selectedDay = days[indexes[2]];
                },
                children: [
                  // 年列
                  FPickerWheel(
                    flex: 1,
                    loop: false,
                    itemExtent: 36,
                    children: years
                        .map(
                          (y) => Center(
                            child: Text(
                              '$y年',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  // 月列
                  FPickerWheel(
                    flex: 1,
                    loop: false,
                    itemExtent: 36,
                    children: months
                        .map(
                          (m) => Center(
                            child: Text(
                              '$m月',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  // 日列（1-31）
                  FPickerWheel(
                    flex: 1,
                    loop: false,
                    itemExtent: 36,
                    children: days
                        .map(
                          (d) => Center(
                            child: Text(
                              '$d日',
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
