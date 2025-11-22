import 'package:dio/dio.dart';
import 'http_client.dart';

abstract class ApiClient {
  final HttpClient _client = HttpClient();

  Dio get dio => _client.dio;

  /// safeCall 统一输出 Map<String, dynamic>
  Future<Map<String, dynamic>> safeCall(
    Future<Response> Function() request,
  ) async {
    try {
      final Response res = await request();

      // 业务层统一解析 success/error/data
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

  /// 解析后端格式：
  /// { success: true/false, error: "", data: {...} }
  Map<String, dynamic> _handleResponse(Response res) {
    final body = res.data;

    if (body is! Map) {
      throw AppNetworkException(
        '非法响应格式（必须是 Map）',
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

    if (body['success'] != true) {
      throw AppNetworkException(
        body['error']?.toString() ?? '业务错误',
        code: res.statusCode,
        data: body,
      );
    }

    final data = body['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw AppNetworkException(
      'data 必须是 Map<String, dynamic>',
      code: res.statusCode,
      data: body,
    );
  }
}
