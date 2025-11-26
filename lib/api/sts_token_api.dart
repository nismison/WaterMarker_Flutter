// lib/api/sts_token_api.dart

import 'package:water_marker_test2/api/api_client.dart';
import 'package:water_marker_test2/models/sts_token_model.dart';

/// STS Token 相关接口封装。
class StsTokenApi extends ApiClient {
  /// 获取当前有效的 COS STS 信息。
  ///
  /// 对应后端：GET /api/sts/token
  ///
  /// 推荐后端返回格式：
  /// {
  ///   "success": true,
  ///   "error": "",
  ///   "data": { ...STS JSON... }
  /// }
  Future<StsTokenModel> fetchStsToken() async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.get('/api/sts/token');
    });

    return StsTokenModel.fromJson(data);
  }
}
