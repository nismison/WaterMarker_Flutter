import 'package:dio/dio.dart';
import 'http_client.dart';

abstract class ApiClient {
  final HttpClient _client = HttpClient();

  Dio get dio => _client.dio;

  /// 统一处理：
  /// - DioException
  /// - 后端 success=false
  /// - 抽取 data 字段为 Map<String, dynamic>
  Future<Map<String, dynamic>> safeCall(
    Future<Response> Function() request,
  ) async {
    try {
      final Response res = await request();
      return _handleResponse(res);
    } on DioException catch (e) {
      throw AppNetworkException(
        e.message ?? '网络异常',
        code: e.response?.statusCode,
        data: e.response?.data,
      );
    } on AppNetworkException {
      rethrow;
    } catch (e) {
      throw AppNetworkException(e.toString());
    }
  }

  /// 预期后端格式：
  /// {
  ///   "success": true/false,
  ///   "error": "错误信息或空字符串",
  ///   "data": {...}  // 统一为对象
  /// }
  Map<String, dynamic> _handleResponse(Response res) {
    final body = res.data;

    if (body is! Map) {
      throw AppNetworkException(
        '非法响应格式（必须是 JSON 对象）',
        code: res.statusCode,
        data: res.data,
      );
    }

    if (!body.containsKey('success')) {
      throw AppNetworkException(
        '缺少 success 字段',
        code: res.statusCode,
        data: body,
      );
    }

    final bool success = body['success'] == true;

    if (!success) {
      throw AppNetworkException(
        body['error']?.toString() ?? '业务错误',
        code: res.statusCode,
        data: body,
      );
    }

    /// success = true
    final data = body['data'];

    if (data == null) {
      // 允许 data 为 null，统一转成空 Map，调用方更好处理
      return <String, dynamic>{};
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    // 如果真有特殊接口想返回 list/原始类型，建议你后端再包一层；
    // 如果现在已经有了，会直接在这里暴露出来，方便你回头改。
    throw AppNetworkException(
      'data 必须是 JSON 对象（Map），当前类型: ${data.runtimeType}',
      code: res.statusCode,
      data: body,
    );
  }
}
