import 'package:flutter/material.dart';
import '../models/user.dart';
import '../core/database_helper.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<User> _users = [];

  List<User> get users => _users;

  Future<void> loadUsers() async {
    final db = await _dbHelper.database;
    final userMaps = await db.query('users', orderBy: 'created_at DESC');
    _users = userMaps.map((m) => User.fromMap(m)).toList();
    notifyListeners();
  }

  Future<String?> addUser(User user, String password) async {
    try {
      // Validate username
      final usernameValidation = AuthService.validateUsername(user.username);
      if (usernameValidation != null) return usernameValidation;

      // Validate password
      final passwordValidation = AuthService.validatePassword(password);
      if (passwordValidation != null) return passwordValidation;

      // Check if username already exists
      final db = await _dbHelper.database;
      final existing = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [user.username],
      );

      if (existing.isNotEmpty) {
        return 'Username already exists';
      }

      // Hash password and create user
      final passwordHash = AuthService.hashPassword(password);
      final userWithHash = user.copyWith(passwordHash: passwordHash);

      await db.insert('users', userWithHash.toMap());
      await loadUsers();
      return null; // Success
    } catch (e) {
      debugPrint('Add user error: $e');
      return 'An error occurred while adding user';
    }
  }

  Future<String?> updateUser(User user) async {
    try {
      // Validate username
      final usernameValidation = AuthService.validateUsername(user.username);
      if (usernameValidation != null) return usernameValidation;

      // Check if username is taken by another user
      final db = await _dbHelper.database;
      final existing = await db.query(
        'users',
        where: 'username = ? AND id != ?',
        whereArgs: [user.username, user.id],
      );

      if (existing.isNotEmpty) {
        return 'Username already exists';
      }

      await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      await loadUsers();
      return null; // Success
    } catch (e) {
      debugPrint('Update user error: $e');
      return 'An error occurred while updating user';
    }
  }

  Future<String?> deleteUser(int id) async {
    try {
      final db = await _dbHelper.database;
      
      // Prevent deleting the last admin
      final adminCount = await db.rawQuery(
        "SELECT COUNT(*) as count FROM users WHERE role = 'ADMIN' AND is_active = 1"
      );
      final count = adminCount.first['count'] as int;
      
      final userToDelete = _users.firstWhere((u) => u.id == id);
      if (userToDelete.role == UserRole.admin && count <= 1) {
        return 'Cannot delete the last admin user';
      }

      await db.delete('users', where: 'id = ?', whereArgs: [id]);
      await loadUsers();
      return null; // Success
    } catch (e) {
      debugPrint('Delete user error: $e');
      return 'An error occurred while deleting user';
    }
  }

  Future<String?> toggleUserStatus(int id) async {
    try {
      final db = await _dbHelper.database;
      final user = _users.firstWhere((u) => u.id == id);

      // Prevent deactivating the last admin
      if (user.isActive && user.role == UserRole.admin) {
        final adminCount = await db.rawQuery(
          "SELECT COUNT(*) as count FROM users WHERE role = 'ADMIN' AND is_active = 1"
        );
        final count = adminCount.first['count'] as int;
        if (count <= 1) {
          return 'Cannot deactivate the last admin user';
        }
      }

      await db.update(
        'users',
        {'is_active': user.isActive ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadUsers();
      return null; // Success
    } catch (e) {
      debugPrint('Toggle user status error: $e');
      return 'An error occurred while updating user status';
    }
  }

  Future<String?> resetPassword(int id, String newPassword) async {
    try {
      // Validate password
      final passwordValidation = AuthService.validatePassword(newPassword);
      if (passwordValidation != null) return passwordValidation;

      final passwordHash = AuthService.hashPassword(newPassword);
      final db = await _dbHelper.database;
      await db.update(
        'users',
        {'password_hash': passwordHash},
        where: 'id = ?',
        whereArgs: [id],
      );
      return null; // Success
    } catch (e) {
      debugPrint('Reset password error: $e');
      return 'An error occurred while resetting password';
    }
  }
}
