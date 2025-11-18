// lib/utils/watermark/encryption.dart
import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/cupertino.dart';

/// 固定 AES 密钥，必须 16 字节
const String aesKey = 'e373d090928170eb';

/// 固定参数
const int fixedOr = 2;

/// 坐标范围
const Map<String, double> coordRange = {
  "lat_min": 22.763168,
  "lat_max": 22.764769,
  "lon_min": 108.430403,
  "lon_max": 108.431633,
};

/// 生成随机坐标
Map<String, dynamic> generateRandomCoordinates() {
  final rand = Random();
  final lat =
      coordRange["lat_min"]! +
          rand.nextDouble() * (coordRange["lat_max"]! - coordRange["lat_min"]!);
  final lon =
      coordRange["lon_min"]! +
          rand.nextDouble() * (coordRange["lon_max"]! - coordRange["lon_min"]!);
  return {
    "c": "GCJ-02",
    "la": double.parse(lat.toStringAsFixed(6)),
    "lo": double.parse(lon.toStringAsFixed(6)),
    "n": "",
  };
}

/// 构造水印 JSON 数据
Map<String, dynamic> createWatermarkData({
  required int timestamp,
  required int s,
  required String n,
  bool useRandomCoords = true,
}) {
  final data = {
    "g": useRandomCoords
        ? generateRandomCoordinates()
        : {"c": "GCJ-02", "la": 22.764439, "lo": 108.432947, "n": ""},
    "n": n,
    "or": fixedOr,
    "ot": timestamp,
    "s": s,
  };
  debugPrint(jsonEncode(data));
  return data;
}

/// AES-128-ECB + PKCS7 加密
String encryptWatermark(Map<String, dynamic> data) {
  final key = encrypt.Key.fromUtf8(aesKey);
  final encryptor = encrypt.Encrypter(
    encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: 'PKCS7'),
  );

  final jsonString = jsonEncode(data);
  final encrypted = encryptor.encrypt(jsonString, iv: encrypt.IV.fromLength(0));

  return base64Encode(encrypted.bytes);
}

/// AES-128-ECB + PKCS7 解密（字符串密钥）
///
/// :param encryptedB64: Base64 编码密文
/// :returns: 解析后的 JSON（Map），解密错误返回 null
Map<String, dynamic>? decryptWatermark(String encryptedB64) {
  try {
    // Base64 解码
    final encryptedBytes = base64Decode(Uri.decodeComponent(encryptedB64));

    // AES-ECB + PKCS7 解密
    final key = encrypt.Key.fromUtf8(aesKey);
    final decryptor = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: 'PKCS7'),
    );
    final decrypted = decryptor.decrypt(
      encrypt.Encrypted(encryptedBytes),
      iv: encrypt.IV.fromLength(0),
    );

    debugPrint("解密得到: $decrypted");

    // JSON 解析
    return jsonDecode(decrypted);

  } catch (e, stacktrace) {
    debugPrint("解密失败: $e");
    debugPrint("$stacktrace");
    return null;
  }
}
