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

  /// 完成工单。
  ///
  /// 对应后端：POST /api/fm/complete
  ///
  /// 请求 JSON Body：
  /// {
  ///   "keyword": "xxx",      // 和 order_id 二选一
  ///   "order_id": "123",     // 和 keyword 二选一
  ///   "user_name": "张三",
  ///   "user_number": "10695306"
  /// }
  ///
  /// 约束：
  /// - user_name / user_number 必填
  /// - keyword 和 order_id 不能同时为空，也不能同时有值
  ///
  /// 成功响应：
  /// {
  ///   "success": true,
  ///   "error": "",
  ///   "data": { ...任意结构，由 handler 返回... }
  /// }
  ///
  /// 失败时会通过 AppNetworkException 抛出，
  /// 例如：
  /// - "keyword和order_id不能同时使用" （code: ORDER_ALREADY_PROCESSED）
  /// - "未找到工单" （code: ORDER_NOT_FOUND）
  Future<FmCompleteTaskResult> completeTask({
    required String userName,
    required String userNumber,
    String? keyword,
    String? orderId,
  }) async {
    // 简单前置校验，防止前端把非法组合直接打到后端
    if ((keyword == null || keyword.trim().isEmpty) &&
        (orderId == null || orderId.trim().isEmpty)) {
      throw ArgumentError('keyword 和 orderId 不能同时为空');
    }
    if (keyword != null &&
        keyword.trim().isNotEmpty &&
        orderId != null &&
        orderId.trim().isNotEmpty) {
      throw ArgumentError('keyword 和 orderId 不能同时有值');
    }

    final Map<String, dynamic> data = await safeCall(() {
      return dio.post(
        '/api/fm/complete',
        data: <String, dynamic>{
          'keyword': keyword?.trim(),
          'order_id': orderId?.trim(),
          'user_name': userName.trim(),
          'user_number': userNumber.trim(),
        },
      );
    });

    return FmCompleteTaskResult.fromJson(data);
  }
}
