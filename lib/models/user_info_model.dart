class UserInfoModel {
  final int id;
  final String name;
  final String userNumber;
  final String phone;
  final String deviceModel;
  final String deviceId;

  UserInfoModel({
    required this.id,
    required this.name,
    required this.userNumber,
    required this.phone,
    required this.deviceModel,
    required this.deviceId,
  });

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      id: json['id'] as int,
      name: json['name'] as String,
      userNumber: json['userNumber'] as String,
      phone: json['phone'] as String,
      deviceModel: json['device_model'] as String,
      deviceId: json['device_id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'userNumber': userNumber,
    'phone': phone,
    'device_model': deviceModel,
    'device_id': deviceId,
  };
}
