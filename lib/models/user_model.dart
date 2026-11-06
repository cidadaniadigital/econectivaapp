import 'dart:convert';

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profile,
    this.phone,
    this.password,
    this.createdAt,
    this.updatedAt,
  });

  int id;
  String name;
  String email;
  int profile;
  String? phone;
  String? password;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      profile: _parseInt(json['profile']),
      phone: json['phone']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name.trim(),
        'email': email.trim(),
        'password': (password ?? '').trim(),
        'profile': profile,
        'phone': (phone ?? '').trim(),
      };

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'profile': profile,
      'phone': (phone ?? '').trim(),
    };

    final String pwd = (password ?? '').trim();
    if (pwd.isNotEmpty) {
      map['password'] = pwd;
    }

    return map;
  }

  static List<UserModel> fromResponseBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List<dynamic>) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final users = decoded['users'] ?? decoded['data'] ?? decoded['items'];
      if (users is List<dynamic>) {
        return users
            .whereType<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList();
      }
    }

    return const <UserModel>[];
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
