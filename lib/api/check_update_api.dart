import 'package:water_marker_test2/api/api_client.dart';
import 'package:water_marker_test2/models/check_update_model.dart';

class CheckUpdateApi extends ApiClient {
  /// 拉取最新更新信息
  ///
  /// 后端必须返回：
  /// { "success": true, "data": { ... } }
  Future<CheckUpdateModel> fetchLatest() async {
    final data = await safeCall(() => dio.get('/api/check_update'));

    return CheckUpdateModel.fromJson(data);
  }
}
