import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:watermarker_v2/models/app_config_model.dart';
import 'package:watermarker_v2/services/image_sync_service.dart';

/// 所有 background_fetch 触发时统一走这里。
///
/// [taskId]：
///   - 默认的周期任务一般是插件自带的默认 ID，你可以只忽略它；
///   - 如果以后引入自定义 Task（scheduleTask），可以按 taskId 做分发。
///
/// [isHeadless]：
///   - true：表示当前运行在 Android headless isolate 中，UI 层不在前台；
///   - false：表示当前 App 进程还在（可能在前台，也可能在后台）。
///
/// 注意：
/// - 这里适合做「短时间、轻量」的任务：
///   - 调接口同步状态；
///   - 写少量本地 DB；
///   - 简单的清理工作；
/// - 不要在这里做大图像处理、复杂计算，避免被系统杀掉，
///   这类重任务建议仍然在前台配合 loading 来做。
Future<void> handleBackgroundFetch(
  String taskId, {
  required bool isHeadless,
}) async {
  // 举例：如果需要按 taskId 分发任务
  // if (taskId == 'com.watermarker_v2.special_task') {
  //   await _handleSpecialTask(isHeadless: isHeadless);
  //   return;
  // }

  // 默认任务逻辑
  await _handleDefaultPeriodicTask(isHeadless: isHeadless);
}

/// 示例：默认的周期任务逻辑。
///
/// 你可以把你现在希望“定时执行”的代码挪到这里。
Future<void> _handleDefaultPeriodicTask({required bool isHeadless}) async {
  // 这是示例伪代码，请换成你的真实业务逻辑：
  //
  // 例如：
  ///
  ///   - 周期性拉取「待处理工单」状态，并写入本地 DB；
  ///   - 周期性上报心跳、设备信息等。

  // try {
  //   final result = await OrderApi.syncPendingOrders();
  //   await LocalOrderRepository.savePendingOrders(result);
  //
  //   Logger.i('[BackgroundJob] syncPendingOrders success '
  //       '(headless: $isHeadless)');
  // } catch (e, stack) {
  //   Logger.e('[BackgroundJob] syncPendingOrders error: $e\n$stack');
  // }

  // 暂时给一个占位实现，避免你忘了改还能编译通过：
  // TODO: 在这里填入你的定时任务业务逻辑
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString("app_config");
  if (jsonStr == null) return;

  try {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final config = AppConfigModel.fromJson(data);
    final prodService = ImageSyncService(isUpload: true);
    await prodService.syncAllImages(config, notify: true);
  } catch (_) {
    return;
  }
}
