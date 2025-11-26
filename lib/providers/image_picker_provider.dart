import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:watermarker_v2/models/user_info_model.dart';

/// @description 管理全局图片选择与统一时间、日期
class ImagePickerProvider extends ChangeNotifier {
  final List<XFile> _pickedImages = [];
  final int maxImages = 9;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  List<Map<String, dynamic>> userList = [];

  ImagePickerProvider();

  UserInfoModel? selectedUser; // 当前选中的用户数据

  List<XFile> get pickedImages => List.unmodifiable(_pickedImages);

  List<String> get pickedPaths => _pickedImages.map((e) => e.path).toList();

  bool get canAddMore => _pickedImages.length < maxImages;

  void setSelected(List<String> paths) {
    // 去重
    final unique = paths.toSet().toList();

    // 限制最大数量
    final limit = unique.take(maxImages).toList();

    // 覆盖当前已选
    _pickedImages
      ..clear()
      ..addAll(limit.map((p) => XFile(p)));

    notifyListeners();
  }

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

  void updateUser(UserInfoModel user) {
    selectedUser = user;
    notifyListeners();
  }

  String get selectedUserName => selectedUser?.name ?? "未选择";

  String get selectedUserNumber => selectedUser?.userNumber.toString() ?? "";
}
