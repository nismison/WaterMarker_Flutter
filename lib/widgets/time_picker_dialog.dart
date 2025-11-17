import 'package:flutter/material.dart';

/**
 * @description 时间选择弹窗：小时-分钟，滚轮选择，选中项有半透明蓝色背景
 *
 * @param context 上下文
 * @param initialTime 初始时间
 * @param onSelected 选择完成回调
 */
void showTimePickerDialog({
  required BuildContext context,
  required TimeOfDay initialTime,
  required ValueChanged<TimeOfDay> onSelected,
}) {
  int selectedHour = initialTime.hour;
  int selectedMinute = initialTime.minute;

  final FixedExtentScrollController hourController =
  FixedExtentScrollController(initialItem: selectedHour);
  final FixedExtentScrollController minuteController =
  FixedExtentScrollController(initialItem: selectedMinute);

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
                  '选择时间',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      // 小时滚轮
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 36,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            ListWheelScrollView.useDelegate(
                              controller: hourController,
                              itemExtent: 36,
                              perspective: 0.002,
                              physics: const FixedExtentScrollPhysics(),
                              overAndUnderCenterOpacity: 0.3,
                              onSelectedItemChanged: (index) {
                                if (index < 0 || index >= 24) {
                                  return;
                                }
                                setState(() {
                                  selectedHour = index;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (_, index) {
                                  if (index < 0 || index >= 24) {
                                    return null;
                                  }
                                  final bool isSelected =
                                      index == selectedHour;
                                  final text =
                                  index.toString().padLeft(2, '0');
                                  return Center(
                                    child: Text(
                                      text,
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
                      // 分钟滚轮
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 36,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            ListWheelScrollView.useDelegate(
                              controller: minuteController,
                              itemExtent: 36,
                              perspective: 0.002,
                              physics: const FixedExtentScrollPhysics(),
                              overAndUnderCenterOpacity: 0.3,
                              onSelectedItemChanged: (index) {
                                if (index < 0 || index >= 60) {
                                  return;
                                }
                                setState(() {
                                  selectedMinute = index;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (_, index) {
                                  if (index < 0 || index >= 60) {
                                    return null;
                                  }
                                  final bool isSelected =
                                      index == selectedMinute;
                                  final text =
                                  index.toString().padLeft(2, '0');
                                  return Center(
                                    child: Text(
                                      text,
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
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSelected(
                      TimeOfDay(
                        hour: selectedHour,
                        minute: selectedMinute,
                      ),
                    );
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
