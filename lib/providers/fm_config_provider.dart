// lib/providers/fm_config.dart

import 'package:flutter/foundation.dart';
import 'package:watermarker_v2/models/user_info_model.dart';
import 'package:watermarker_v2/models/fm_model.dart';

/// FM 相关配置：
/// - 用户信息
/// - 签到页的班次信息 & 打卡记录缓存
class FmConfigProvider extends ChangeNotifier {
  UserInfoModel? _userInfo;

  /// 签到页最近一次的接口结果（班次 + 打卡记录）
  FmCheckinRecordResult? _checkinData;

  /// 当前 FM 用户信息（可能为 null）
  UserInfoModel? get userInfo => _userInfo;

  /// 最近一次的签到数据缓存（可能为 null）
  FmCheckinRecordResult? get checkinData => _checkinData;

  /// 是否已经配置了 FM 用户信息（工单页 / 打卡页可用）
  bool get hasUserInfo => _userInfo != null;

  /// 简单的语法糖：是否已准备好调用 FM 接口
  bool get isReadyForFm =>
      _userInfo != null &&
          _userInfo!.userNumber.isNotEmpty &&
          _userInfo!.phone.isNotEmpty;

  /// 一次性设置用户信息。
  void setUserInfo(UserInfoModel info) {
    _userInfo = info;
    notifyListeners();
  }

  /// 使用新的 UserInfoModel 更新。
  void updateUserInfo(UserInfoModel Function(UserInfoModel current) updater) {
    if (_userInfo == null) return;
    _userInfo = updater(_userInfo!);
    notifyListeners();
  }

  /// 更新签到数据缓存（班次 + 打卡记录）。
  ///
  /// 在接口请求成功后调用，供页面初始化时直接使用。
  void setCheckinData(FmCheckinRecordResult data) {
    _checkinData = data;
    notifyListeners();
  }

  /// 清空签到数据缓存。
  void clearCheckinData() {
    _checkinData = null;
    notifyListeners();
  }

  /// 清空用户信息（例如退出登录时调用），顺带清空签到缓存。
  void clearUserInfo() {
    _userInfo = null;
    _checkinData = null;
    notifyListeners();
  }
}
