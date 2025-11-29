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
  static Future<String> getDeviceModel({bool onlyModel = false}) async {
    try {
      final android = await _deviceInfo.androidInfo;

      // 原始值
      final rawBrand = (android.brand).trim();
      final rawModel = (android.model).trim();

      // 规范化：
      // brand 全小写，如 "xiaomi" / "huawei"
      // model 全大写，如 "24069RA21C" / "ADY-AL10"
      final brand = rawBrand.isNotEmpty ? rawBrand.toLowerCase() : '';
      final model = rawModel.isNotEmpty ? rawModel.toUpperCase() : '';

      if (onlyModel) {
        // 只要 model，没拿到 model 时再退化为 brand 或默认值
        if (model.isNotEmpty) {
          return model;
        } else if (brand.isNotEmpty) {
          return brand;
        } else {
          return 'Android Unknown';
        }
      }

      // 默认行为：返回 "brand model" 或退化逻辑
      if (brand.isNotEmpty && model.isNotEmpty) {
        return '$brand $model';
      } else if (model.isNotEmpty) {
        return model; // 只返回大写型号
      } else if (brand.isNotEmpty) {
        return brand; // 只返回小写品牌
      } else {
        return 'Android Unknown';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }
}
