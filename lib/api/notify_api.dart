import 'package:watermarker_v2/api/api_client.dart';

/// 通知相关 API
class NotifyApi extends ApiClient {
  /// 发送通知
  ///
  /// Flask 接口：
  ///     POST /api/send_notify
  ///     { "content": "xxx" }
  ///
  /// 返回 success:true/false，由 safeCall 自动解析。
  ///
  /// 调用示例：
  /// final notifyApi = NotifyApi();
  ///
  /// try {
  ///   await notifyApi.sendNotify("上传完成！文件数 12 张");
  ///   print("通知已发送");
  /// } catch (e) {
  ///   print("通知发送失败: $e");
  /// }
  Future<void> sendNotify(String content) async {
    // safeCall 返回的是 Map<String, dynamic>（data 字段）
    // 但后端 /api/send_notify 没有 data 字段，只返回 success,
    // 所以 safeCall 内部会返回一个空 Map，但我们不需要它。
    await safeCall(() {
      return dio.post('/api/send_notify', data: {'content': content});
    });
  }
}
