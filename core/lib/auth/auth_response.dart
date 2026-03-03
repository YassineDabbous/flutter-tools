extension Authorization on AuthResponse {
  bool hasAbilityTo(String ability) => abilities.contains(ability) || abilities.contains('*') || abilities.isEmpty;
  bool hasPermissionTo(int permission) => permissions.contains(permission) || permissions.contains('*');
  //
  // bool get canCreatePost => hasAbilityTo(Abilities.CONTENT_CREATOR) && hasPermissionTo(Permissions.MANAGE_POSTS);
  // bool get canManagePosts => hasPermissionTo(Permissions.MANAGE_POSTS);
  // bool get canManageBanners => hasPermissionTo(Permissions.MANAGE_BANNERS);
  // bool get canManageOrders => hasPermissionTo(Permissions.MANAGE_ORDERS);
  // bool get canManageShipments => hasPermissionTo(Permissions.MANAGE_SHIPMENTS);
  // bool get canManageReports => hasPermissionTo(Permissions.MANAGE_REPORTS);
  // bool get canManageTenants => hasPermissionTo(Permissions.MANAGE_TENANTS);
  // bool get canManageHisTenant => hasPermissionTo(Permissions.MANAGE_TENANTS) || hasPermissionTo(Permissions.TENANT_EDIT_CONFIG);
}

// extension MEMBERSHIP on AuthResponse {
//   bool get isDriver => this.user.type == AccountSubType.DRIVER;
//   bool get isSeller => this.user.type == AccountType.BUSINESS;
// }

class AuthUser {
  AuthUser({
    required this.id,
    required this.type,
    required this.name,
    required this.photo,
    // required this.categoryId,
    // required this.locationId,
  });
  int id;
  String type;
  String name;
  String? photo;
  // int? categoryId;
  // int? sendReceive;
  // int? repositoryId;
  // int? locationId;
  String get photoUrl => photo ?? 'https://i.ytimg.com/vi/sSISeekwthY/hqdefault.jpg';
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      type: json['type'],
      name: json['full_name'],
      photo: json['profile_picture_url'],
      // categoryId: json['category_id'],
      // locationId: json['location_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'full_name': name,
    'profile_picture_url': photo,
    // 'category_id': categoryId,
    // 'location_id': locationId,
  };
}

class AuthResponse {
  AuthUser user;
  String token;
  List<String> abilities;
  List<int> permissions;

  AuthResponse({required this.user, required this.token, required this.abilities, required this.permissions});
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: AuthUser.fromJson(json['user']),
      token: json['token'],
      permissions: List<int>.from((json["permissions"] ?? []).map((x) => x)),
      abilities: List<String>.from((json["abilities"] ?? ['*']).map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'token': token,
    'permissions': List<dynamic>.from(permissions.map((x) => x)),
    'abilities': List<dynamic>.from(abilities.map((x) => x)),
  };
}
