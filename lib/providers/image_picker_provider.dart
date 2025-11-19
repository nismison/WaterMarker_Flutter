import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// @description 管理全局图片选择与统一时间、日期
class ImagePickerProvider extends ChangeNotifier {
  final List<XFile> _pickedImages = [];
  final int maxImages = 9;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  static const String _userListKey = 'userList';

  List<Map<String, dynamic>> userList = [];

  ImagePickerProvider() {
    _initUserList();
  }

  Map<String, dynamic>? selectedUser; // 当前选中的用户数据

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

  void updateUser(Map<String, dynamic> user) {
    selectedUser = user;
    notifyListeners();
  }

  String get selectedUserName => selectedUser?['name'] ?? "未选择";
  String get selectedUserNumber => selectedUser?['number']?.toString() ?? "";

  /// 初始化用户列表
  Future<void> _initUserList() async {
    final prefs = await SharedPreferences.getInstance();

    final storedList = prefs.getString(_userListKey);
    if (storedList == null) {
      debugPrint("SharedPrefs中无用户列表，初始化为空列表");
      await prefs.setString(_userListKey, jsonEncode([])); // 写入空列表
      userList = [];
    } else {
      try {
        userList = List<Map<String, dynamic>>.from(
          jsonDecode(storedList),
        );
        debugPrint("用户列表加载成功: $userList");
        selectedUser = userList.first;
      } catch (e) {
        debugPrint("用户列表加载失败，重置为空列表: $e");
        userList = [];
      }
    }

    notifyListeners();
  }

  /// 更新用户列表（支持添加、替换等）
  Future<void> updateUserList(List<Map<String, dynamic>> newList) async {
    userList = newList;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userListKey, jsonEncode(newList));

    notifyListeners();
  }

  /// 添加一个用户
  Future<void> addUser(Map<String, dynamic> user) async {
    userList.add(user);
    await updateUserList(userList);
  }

  /// 清空用户列表并同步SharedPrefs
  Future<void> clearUserList() async {
    userList = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userListKey, jsonEncode([]));
    notifyListeners();
  }
}
