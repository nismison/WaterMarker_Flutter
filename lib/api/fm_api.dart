import 'package:watermarker_v2/api/base/api_client.dart';
import 'package:watermarker_v2/models/fm_model.dart';

/// FM 相关接口封装：
///
/// - POST  /api/fm/pending_accept     获取待接单工单
/// - POST  /api/fm/pending_process    获取待处理工单
/// - POST  /api/fm/accept_task        接单
/// - POST  /api/fm/accept_muti_task   批量接单
class FmApi extends ApiClient {
  /// 获取待接单工单列表。
  ///
  /// 对应后端：POST /api/fm/pending_accept
  ///
  /// 请求（JSON Body）：
  /// {
  ///   "user_number": "xxx"
  /// }
  ///
  /// 响应（成功）：
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "items": [ {...}, {...} ]
  ///   }
  /// }
  Future<FmTaskListResult> fetchPendingAccept({
    required String userNumber,
  }) async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.post(
        '/api/fm/pending_accept',
        // 说明：后端用 request.get_json()，这里用 data 传 JSON Body。
        data: <String, dynamic>{'user_number': userNumber},
      );
    });

    return FmTaskListResult.fromJson(data);
  }

  /// 获取待处理工单列表。
  ///
  /// 对应后端：GET /api/fm/pending_process
  ///
  /// 请求（JSON Body）：
  /// {
  ///   "user_number": "xxx"
  /// }
  ///
  /// 响应（成功）：
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "items": [ {...}, {...} ]
  ///   }
  /// }
  Future<FmTaskListResult> fetchPendingProcess({
    required String userNumber,
  }) async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.post(
        '/api/fm/pending_process',
        data: <String, dynamic>{'user_number': userNumber},
      );
    });

    return FmTaskListResult.fromJson(data);
  }

  /// 接单。
  ///
  /// 对应后端：GET /api/fm/accept_task
  ///
  /// 请求（JSON Body）：
  /// {
  ///   "user_number": "xxx",
  ///   "order_id": "123"
  /// }
  ///
  /// 响应（成功）：
  /// {
  ///   "success": true,
  ///   "data": { ...FM 接口原始返回... }
  /// }
  ///
  /// 注意：当前约定 data 为 JSON 对象（Map），否则会触发
  /// ApiClient._handleResponse 中的类型检查异常。
  Future<FmAcceptTaskResult> acceptTask({
    required String userNumber,
    required String orderId,
  }) async {
    final Map<String, dynamic> data = await safeCall(() {
      return dio.post(
        '/api/fm/accept_task',
        data: <String, dynamic>{'user_number': userNumber, 'order_id': orderId},
      );
    });

    return FmAcceptTaskResult.fromJson(data);
  }

  /// 批量接单。
  ///
  /// 对应后端：GET /api/fm/accept_muti_task
  ///
  /// 请求（JSON Body）：
  /// {
  ///   "user_number": "xxx",
  ///   "order_ids": ["1", "2", ...]
  /// }
  ///
  /// 响应（成功）：
  /// {
  ///   "success": true,
  ///   "data": {}
  /// }
  ///
  /// 由于 data 始终为空对象，这里直接返回 void，
  /// 调用方只需关心是否抛出异常即可。
  Future<void> acceptMultiTask({
    required String userNumber,
    required List<String> orderIds,
  }) async {
    await safeCall(() {
      return dio.post(
        '/api/fm/accept_muti_task',
        data: <String, dynamic>{
          'user_number': userNumber,
          'order_ids': orderIds,
        },
      );
    });
  }
}
