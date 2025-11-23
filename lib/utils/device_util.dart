import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// 设备工具类：用于获取“品牌 + 型号”
///
/// 示例返回：
/// - Android: "xiaomi 24069RA21C"
/// - Android: "huawei ADY-AL10"
/// - iOS: "iPhone iPhone16,2"
class DeviceUtil {
  DeviceUtil._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 获取设备型号（带品牌），失败时返回 "Unknown Device"
  static Future<String> getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;

        // 原始值
        final rawBrand = (android.brand ?? '').trim();
        final rawModel = (android.model ?? '').trim();

        // 规范化：
        // brand 全小写，如 "xiaomi" / "huawei"
        // model 全大写，如 "24069RA21C" / "ADY-AL10"
        final brand = rawBrand.isNotEmpty ? rawBrand.toLowerCase() : '';
        final model = rawModel.isNotEmpty ? rawModel.toUpperCase() : '';

        if (brand.isNotEmpty && model.isNotEmpty) {
          return '$brand $model';
        } else if (model.isNotEmpty) {
          return model; // 只返回大写型号
        } else if (brand.isNotEmpty) {
          return brand; // 只返回小写品牌
        } else {
          return 'Android Unknown';
        }
      }

      if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        final name = (ios.name ?? '').trim(); // 设备名
        final machine = (ios.utsname.machine ?? '').trim(); // 硬件型号 "iPhone16,2"

        // iOS 这边我保持原样，不做大小写转换，如需也统一可以再调
        if (name.isNotEmpty && machine.isNotEmpty) {
          return '$name $machine';
        } else if (machine.isNotEmpty) {
          return machine;
        } else if (name.isNotEmpty) {
          return name;
        } else {
          return 'iOS Unknown';
        }
      }

      // 其他平台（web / desktop）
      final info = await _deviceInfo.deviceInfo;
      final model = info.data['model']?.toString().trim();
      if (model != null && model.isNotEmpty) {
        return model;
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }
}
