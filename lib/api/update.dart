import 'package:watermarker_v2/api/base/api_client.dart';
import 'package:watermarker_v2/models/check_update_model.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:watermarker_v2/api/base/http_client.dart';

class UpdateApi extends ApiClient {
  /// 拉取最新更新信息
  ///
  /// 后端必须返回：
  /// { "success": true, "data": { ... } }
  Future<CheckUpdateModel> fetchLatest() async {
    final data = await safeCall(() => dio.get('/api/check_update'));

    return CheckUpdateModel.fromJson(data);
  }

  /// 下载任意文件（APK、zip、bin 等）
  ///
  /// 参数为 now_url，即 /api/check_update 返回的:
  ///   "/api/download/xxx.apk"
  ///
  /// 返回值为 Uint8List 二进制内容
  ///
  /// 如需保存到本地文件，可用 File(...).writeAsBytes(bytes);
  Future<Uint8List> downloadFile(
      String nowUrl, {
        void Function(double progress)? onProgress,
      }) async {
    try {
      final res = await dio.get<List<int>>(
        nowUrl,
        options: Options(
          responseType: ResponseType.bytes, // 关键：二进制下载
          followRedirects: false,
        ),
        onReceiveProgress: (count, total) {
          if (total > 0 && onProgress != null) {
            final p = count / total;
            onProgress(p); // 回调进度比例(0~1)
          }
        },
      );

      final bytes = res.data;
      if (bytes == null) {
        throw AppNetworkException("下载失败：服务器未返回任何内容", code: res.statusCode);
      }

      return Uint8List.fromList(bytes);
    } on DioException catch (e) {
      throw AppNetworkException(
        e.message ?? '下载失败',
        code: e.response?.statusCode,
        data: e.response?.data,
      );
    }
  }
}
