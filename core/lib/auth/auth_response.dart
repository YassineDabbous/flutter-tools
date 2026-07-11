extension Authorization on AuthResponse {
  bool hasAbilityTo(String ability) =>
      abilities.contains(ability) ||
      abilities.contains('*') ||
      abilities.isEmpty;
  bool hasPermissionTo(dynamic permission) =>
      permissions.contains(permission) || permissions.contains('*');
}

class AuthUser<ID> {
  AuthUser({
    required this.id,
    required this.type,
    required this.name,
    required this.photo,
  });

  ID id;
  String type;
  String name;
  String? photo;

  String get photoUrl =>
      photo ?? 'https://i.ytimg.com/vi/sSISeekwthY/hqdefault.jpg';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as ID,
      type: json['type'] ?? '',
      name: json['full_name'] ?? '',
      photo: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'full_name': name,
    'profile_picture_url': photo,
  };
}

class AuthResponse<ID> {
  AuthUser<ID> user;
  String token;
  List<String> abilities;
  List<dynamic> permissions;

  AuthResponse({
    required this.user,
    required this.token,
    required this.abilities,
    required this.permissions,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: AuthUser<ID>.fromJson(json['user']),
      token: json['token'],
      permissions: List<dynamic>.from(json["permissions"] ?? []),
      abilities: List<String>.from(json["abilities"] ?? ['*']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'token': token,
    'permissions': permissions,
    'abilities': abilities,
  };
}
