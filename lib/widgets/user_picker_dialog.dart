import 'package:flutter/material.dart';

/**
 * @description 用户选择弹窗（基于 List<Map> 数据源）
 *
 * @param context 上下文
 * @param userList 用户列表（包含 name 和 number 字段）
 * @param initialName 初始选中项 name
 * @param onSelected 回调选中的用户对象
 */
void showUserPickerDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> userList,
  required String initialName,
  required Function(Map<String, dynamic>) onSelected,
}) {
  // 查找初始索引
  int initialIndex = userList.indexWhere((u) => u['name'] == initialName);
  if (initialIndex < 0) initialIndex = 0;

  dynamic tempUser = userList[initialIndex];
  int currentIndex = initialIndex;

  final controller = FixedExtentScrollController(initialItem: initialIndex);

  showModalBottomSheet(
    context: context,
    builder: (_) {
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
                  '选择用户',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 高亮背景
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
                        physics: const FixedExtentScrollPhysics(),
                        overAndUnderCenterOpacity: 0.3,
                        onSelectedItemChanged: (index) {
                          if (index < 0 || index >= userList.length) return;
                          setState(() {
                            currentIndex = index;
                            tempUser = userList[index];
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (_, index) {
                            if (index < 0 || index >= userList.length)
                              return null;
                            final u = userList[index];
                            final name = u['name'];
                            final bool isSelected = index == currentIndex;

                            return Center(
                              child: Text(
                                name,
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
                    onSelected(tempUser);
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
