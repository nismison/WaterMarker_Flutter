// lib/api/user_api.dart

import 'package:water_marker_test2/api/api_client.dart';
import 'package:water_marker_test2/models/user_info_model.dart';

class UserApi extends ApiClient {
  /// 新增用户
  ///
  /// 后端：POST /api/users
  /// body: { "name": "...", "userNumber": "1234567" }
  ///
  /// 后端响应（已符合 safeCall 规范）：
  /// {
  ///   "success": true,
  ///   "data": { "id": 1, "name": "...", "userNumber": "1234567" }
  /// }
  Future<UserInfoModel> createUser({
    required String name,
    required String userNumber,
  }) async {
    final data = await safeCall(
          () => dio.post(
        '/api/users',
        data: <String, dynamic>{
          'name': name,
          'userNumber': userNumber,
        },
      ),
    );

    // 这里的 data 已经是 body['data']，类型为 Map<String, dynamic>
    return UserInfoModel.fromJson(data);
  }

  /// 获取全部用户列表（不分页）
  ///
  /// 约定后端 GET /api/users 返回：
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "items": [
  ///       { "id": 1, "name": "张三", "userNumber": "1234567" },
  ///       ...
  ///     ]
  ///   }
  /// }
  ///
  /// safeCall 会：
  ///   - 校验 success
  ///   - 抛出统一的 AppNetworkException
  ///   - 抽取 data => Map< String, dynamic >，这里就是 { "items": [ ... ] }
  Future<List<UserInfoModel>> listUsers() async {
    final data = await safeCall(
          () => dio.get('/api/users'),
    );

    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => UserInfoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
