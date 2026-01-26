enum UserRole { admin, posUser }

class User {
  final int? id;
  final String username;
  final String passwordHash;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'full_name': fullName,
      'role': role == UserRole.admin ? 'ADMIN' : 'POS_USER',
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      fullName: map['full_name'],
      role: map['role'] == 'ADMIN' ? UserRole.admin : UserRole.posUser,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      lastLogin: map['last_login'] != null 
          ? DateTime.parse(map['last_login']) 
          : null,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? fullName,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // Helper to check if user is admin
  bool get isAdmin => role == UserRole.admin;
}
