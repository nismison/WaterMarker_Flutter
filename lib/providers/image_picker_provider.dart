import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/**
 * @description 管理全局图片选择与统一时间、日期
 */
class ImagePickerProvider extends ChangeNotifier {
  final List<XFile> _pickedImages = [];
  final int maxImages = 9;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  // 用户选择
  List<Map<String, dynamic>> userList = [
    {"name": "黄光燃", "number": 2425430}, // 测试数据，后期可动态替换
  ];

  Map<String, dynamic>? selectedUser; // 当前选中的用户数据

  List<XFile> get pickedImages => List.unmodifiable(_pickedImages);
  bool get canAddMore => _pickedImages.length < maxImages;

  Future<void> addImages(List<XFile> images) async {
    _pickedImages.addAll(images.take(maxImages - _pickedImages.length));
    notifyListeners();
  }

  void removeImage(int index) {
    _pickedImages.removeAt(index);
    notifyListeners();
  }

  void updateDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void updateTime(TimeOfDay time) {
    selectedTime = time;
    notifyListeners();
  }

  DateTime get combinedDateTime {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  void updateUser(Map<String, dynamic> user) {
    selectedUser = user;
    notifyListeners();
  }

  String get selectedUserName => selectedUser?['name'] ?? "未选择";
  String get selectedUserNumber => selectedUser?['number']?.toString() ?? "";
}
