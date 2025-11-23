// lib/models/user_info_model.dart

class UserInfoModel {
  final int id;
  final String name;
  final String userNumber;

  UserInfoModel({
    required this.id,
    required this.name,
    required this.userNumber,
  });

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      id: json['id'] as int,
      name: json['name'] as String,
      userNumber: json['userNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'userNumber': userNumber,
  };
}
