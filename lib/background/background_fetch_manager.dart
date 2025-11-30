import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:watermarker_v2/background/background_jobs.dart';

class BackgroundFetchManager {
  BackgroundFetchManager._internal();

  static final BackgroundFetchManager instance =
      BackgroundFetchManager._internal();

  bool _initialized = false;

  Future<void> init({int minimumFetchIntervalMinutes = 15}) async {
    if (_initialized) return;
    _initialized = true;

    final config = BackgroundFetchConfig(
      minimumFetchInterval: minimumFetchIntervalMinutes,
      stopOnTerminate: false,
      startOnBoot: true,
      enableHeadless: true,
      requiredNetworkType: NetworkType.ANY,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    );

    await BackgroundFetch.configure(config, _onEvent, _onTimeout);

    await BackgroundFetch.start();
  }

  Future<void> stop() async {
    await BackgroundFetch.stop();
  }

  Future<void> _onEvent(String taskId) async {
    try {
      await handleBackgroundFetch(taskId, isHeadless: false);
    } catch (e, stack) {
      // TODO: 日志
    } finally {
      BackgroundFetch.finish(taskId);
    }
  }

  Future<void> _onTimeout(String taskId) async {
    BackgroundFetch.finish(taskId);
  }
}
