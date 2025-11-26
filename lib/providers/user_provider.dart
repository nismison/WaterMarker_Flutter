// lib/providers/user_provider.dart

import 'package:flutter/foundation.dart';

import 'package:watermarker_v2/api/http_client.dart';
import 'package:watermarker_v2/api/user_api.dart';

import '../models/user_info_model.dart';

/// 管理用户相关状态的 Provider。
///
/// - 负责持有当前用户列表
/// - 提供「新增用户」和「获取用户列表」方法
/// - 底层通过 UserApi 的 createUser / listUsers 接口与后端交互
class UserProvider extends ChangeNotifier {
  final UserApi _api;

  UserProvider({UserApi? api}) : _api = api ?? UserApi();

  /// 当前所有用户列表
  List<UserInfoModel> _users = [];

  /// 是否正在网络请求中
  bool _loading = false;

  /// 最近一次请求的错误信息（如果有）
  String? _error;

  List<UserInfoModel> get users => List.unmodifiable(_users);
  bool get isLoading => _loading;
  String? get error => _error;

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  /// 对外暴露一个清空错误的方法，方便页面在展示完错误后清理。
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ===========================================================
  // 获取用户列表 —— 调用 listUsers 接口
  // ===========================================================

  /// 从后端拉取用户列表，并更新本地状态。
  ///
  /// 成功：
  ///   - _users 会被整体替换
  ///   - isLoading 会在请求前后自动维护
  ///   - error 置空
  ///
  /// 失败：
  ///   - error 会记录错误信息
  ///   - 异常会继续向上抛出，方便页面按需 catch
  Future<void> fetchUserList() async {
    _setLoading(true);
    _setError(null);

    try {
      final list = await _api.listUsers(); // 调用封装好的接口
      _users = list;
      notifyListeners();
    } on AppNetworkException catch (e) {
      _setError(e.message);
      rethrow;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ===========================================================
  // 新增用户 —— 调用 createUser 接口
  // ===========================================================

  /// 新增用户，成功后会把新用户插入到列表中（默认插在最前面）。
  ///
  /// - name: 用户姓名
  /// - userNumber: 工号 / 编号
  ///
  /// 返回：后端创建成功的用户对象（带 id 等完整信息）。
  Future<UserInfoModel> addUser({
    required String name,
    required String userNumber,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final created = await _api.createUser(
        name: name,
        userNumber: userNumber,
      );

      // 简单策略：新用户插到列表最前面
      _users = [created, ..._users];
      notifyListeners();

      return created;
    } on AppNetworkException catch (e) {
      _setError(e.message);
      rethrow;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
