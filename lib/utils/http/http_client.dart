import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 网络异常的统一模型，用于隔离 Dio 的内部结构。
class AppNetworkException implements Exception {
  final String message;
  final int? code;
  final dynamic data;

  AppNetworkException(this.message, {this.code, this.data});

  @override
  String toString() =>
      'AppNetworkException(message: $message, code: $code, data: $data)';
}

/// 全局单例 Dio 客户端。
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();

  factory HttpClient() => _instance;

  late final Dio dio;

  HttpClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        validateStatus: (code) => code != null && code > 0,
        responseType: ResponseType.json,
      ),
    );

    _addInterceptors();
  }

  /// 默认 BaseUrl（可以在 main.dart 中切换）
  static String _baseUrl = '';

  /// 设置全局 BaseUrl
  static void setBaseUrl(String url) {
    _baseUrl = url;
    HttpClient().dio.options.baseUrl = url;
  }

  /// 请求/响应打印拦截器
  void _addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint('🔵 ===== HTTP REQUEST =====');
            debugPrint('🌐 URL: ${options.uri}');
            debugPrint('📝 METHOD: ${options.method}');
            debugPrint('📦 HEADERS: ${jsonEncode(options.headers)}');
            debugPrint('📤 DATA: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (res, handler) {
          if (kDebugMode) {
            debugPrint('🟢 ===== HTTP RESPONSE =====');
            debugPrint('🌐 URL: ${res.requestOptions.uri}');
            debugPrint('📊 STATUS: ${res.statusCode}');
            debugPrint('📥 DATA: ${res.data}');
          }
          handler.next(res);
        },
        onError: (err, handler) {
          if (kDebugMode) {
            debugPrint('===== HTTP ERROR =====');
            debugPrint('URL: ${err.requestOptions.uri}');
            debugPrint('TYPE: ${err.type}');
            debugPrint('MESSAGE: ${err.message}');
            debugPrint('DATA: ${err.response?.data}');
          }
          handler.next(err);
        },
      ),
    );
  }

  /// 核心通用请求方法
  Future<dynamic> _request(
    String path, {
    required String method,
    Map<String, dynamic>? query,
    dynamic data,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await dio.request(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return response.data;
    } on DioException catch (e) {
      // Dio 5 的新异常模型：DioException 取代 DioError
      throw AppNetworkException(
        e.message ?? 'Network error',
        code: e.response?.statusCode,
        data: e.response?.data,
      );
    } catch (e) {
      throw AppNetworkException(e.toString());
    }
  }

  /// GET
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _request(path, method: 'GET', query: query);
  }

  /// POST
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _request(path, method: 'POST', data: data, query: query);
  }

  /// PUT
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _request(path, method: 'PUT', data: data, query: query);
  }

  /// DELETE
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _request(path, method: 'DELETE', data: data, query: query);
  }

  /// 文件上传
  Future<dynamic> upload(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, dynamic>? fields,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      if (fields != null) ...fields,
      fileField: await MultipartFile.fromFile(filePath),
    });

    return _request(
      path,
      method: 'POST',
      data: formData,
      onSendProgress: onSendProgress,
    );
  }

  /// 文件下载
  Future<void> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      await dio.download(url, savePath, onReceiveProgress: onReceiveProgress);
    } on DioException catch (e) {
      throw AppNetworkException(
        e.message ?? '下载失败',
        code: e.response?.statusCode,
        data: e.response?.data,
      );
    }
  }
}
