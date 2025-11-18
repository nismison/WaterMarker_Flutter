// lib/utils/watermark/encryption.dart
import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;

/// 固定 AES 密钥，必须 16 字节
const String AES_KEY = 'e373d090928170eb';

/// 固定参数
const int FIXED_OR = 2;

/// 坐标范围
const Map<String, double> COORD_RANGE = {
  "lat_min": 22.763168,
  "lat_max": 22.764769,
  "lon_min": 108.430403,
  "lon_max": 108.431633,
};

/// 生成随机坐标
Map<String, dynamic> generateRandomCoordinates() {
  final rand = Random();
  final lat = COORD_RANGE["lat_min"]! +
      rand.nextDouble() * (COORD_RANGE["lat_max"]! - COORD_RANGE["lat_min"]!);
  final lon = COORD_RANGE["lon_min"]! +
      rand.nextDouble() * (COORD_RANGE["lon_max"]! - COORD_RANGE["lon_min"]!);
  return {
    "c": "GCJ-02",
    "la": double.parse(lat.toStringAsFixed(6)),
    "lo": double.parse(lon.toStringAsFixed(6)),
    "n": ""
  };
}

/// 构造水印 JSON 数据
Map<String, dynamic> createWatermarkData({
  required int timestamp,
  required int s,
  required String n,
  bool useRandomCoords = true,
}) {
  return {
    "g": useRandomCoords ? generateRandomCoordinates() : {
      "c": "GCJ-02",
      "la": 22.764439,
      "lo": 108.432947,
      "n": ""
    },
    "n": n,
    "or": FIXED_OR,
    "ot": timestamp,
    "s": s
  };
}

/// AES-128-ECB + PKCS7
String encryptWatermark(Map<String, dynamic> data) {
  final key = encrypt.Key.fromUtf8(AES_KEY);
  final encryptor = encrypt.Encrypter(
    encrypt.AES(key, mode: encrypt.AESMode.ecb, padding: 'PKCS7'),
  );

  final jsonString = jsonEncode(data);
  final encrypted = encryptor.encrypt(jsonString, iv: encrypt.IV.fromLength(0));

  return base64Encode(encrypted.bytes);
}
