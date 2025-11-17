import 'package:flutter/material.dart';

/**
 * @description 日期选择弹窗：年月日，滚轮选择，选中项有半透明蓝色背景
 *
 * @param context 上下文
 * @param initialDate 初始日期
 * @param onSelected 选择完成回调
 */
void showDatePickerDialog({
  required BuildContext context,
  required DateTime initialDate,
  required ValueChanged<DateTime> onSelected,
}) {
  // 生成未来 365 天的日期列表（可按需调整）
  final List<DateTime> dateList = List.generate(
    365,
        (i) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day).add(Duration(days: i));
    },
  );

  // 找到初始日期所在下标，不存在就用 0
  int initialIndex = dateList.indexWhere((d) =>
  d.year == initialDate.year &&
      d.month == initialDate.month &&
      d.day == initialDate.day);
  if (initialIndex < 0) {
    initialIndex = 0;
  }

  DateTime tempDate = dateList[initialIndex];
  int currentIndex = initialIndex;

  final FixedExtentScrollController controller =
  FixedExtentScrollController(initialItem: initialIndex);

  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    builder: (ctx) {
      return Container(
        height: 280,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                const Text(
                  '选择日期',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 选中项的半透明蓝色背景条
                      Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      ListWheelScrollView.useDelegate(
                        controller: controller,
                        itemExtent: 36,
                        perspective: 0.002,
                        physics: const FixedExtentScrollPhysics(), // 强制停在选项上
                        overAndUnderCenterOpacity: 0.3,
                        onSelectedItemChanged: (index) {
                          if (index < 0 || index >= dateList.length) {
                            return;
                          }
                          setState(() {
                            currentIndex = index;
                            tempDate = dateList[index];
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (_, index) {
                            if (index < 0 || index >= dateList.length) {
                              return null; // 一定要防御负数和越界
                            }
                            final d = dateList[index];
                            final label =
                                "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                            final bool isSelected = index == currentIndex;
                            return Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSelected(tempDate);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
