class AuthUser {
  static const administratorProfile = 40;
  static const participantProfile = 10;
  bool get isAdministrator => profile == administratorProfile;
  final int id;
  final String name;
  final String email;
  final String token;
  final int? profile;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    this.profile,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      token: json['token'] ?? json['plain_text_token'] ?? '',
      profile: int.tryParse(json['profile']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      if (profile != null) 'profile': profile,
    };
  }
}
