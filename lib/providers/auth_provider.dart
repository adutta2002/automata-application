import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/database_helper.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _loadSession();
  }

  // Load saved session on app start
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId != null) {
        final db = await _dbHelper.database;
        final userMaps = await db.query(
          'users',
          where: 'id = ? AND is_active = 1',
          whereArgs: [userId],
        );
        
        if (userMaps.isNotEmpty) {
          _currentUser = User.fromMap(userMaps.first);
        }
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with username and password
  Future<String?> login(String username, String password, {bool rememberMe = false}) async {
    try {
      final db = await _dbHelper.database;
      final userMaps = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (userMaps.isEmpty) {
        return 'Invalid username or password';
      }

      final user = User.fromMap(userMaps.first);

      if (!user.isActive) {
        return 'Account is deactivated. Please contact administrator.';
      }

      if (!AuthService.verifyPassword(password, user.passwordHash)) {
        return 'Invalid username or password';
      }

      // Update last login
      await db.update(
        'users',
        {'last_login': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [user.id],
      );

      _currentUser = user.copyWith(lastLogin: DateTime.now());

      // Save session if remember me
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user.id!);
      }

      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint('Login error: $e');
      return 'An error occurred during login';
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }

  // Check if user has permission for a feature
  bool hasPermission(String feature) {
    if (_currentUser == null) return false;
    if (_currentUser!.isAdmin) return true;

    // POS User permissions
    const posUserPermissions = [
      'create_invoice',
      'view_products',
      'view_services',
      'view_customers',
    ];

    return posUserPermissions.contains(feature);
  }

  // Change password
  Future<String?> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return 'Not logged in';

    try {
      // Verify old password
      if (!AuthService.verifyPassword(oldPassword, _currentUser!.passwordHash)) {
        return 'Current password is incorrect';
      }

      // Validate new password
      final validation = AuthService.validatePassword(newPassword);
      if (validation != null) return validation;

      // Hash and update
      final newHash = AuthService.hashPassword(newPassword);
      final db = await _dbHelper.database;
      await db.update(
        'users',
        {'password_hash': newHash},
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      _currentUser = _currentUser!.copyWith(passwordHash: newHash);
      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint('Change password error: $e');
      return 'An error occurred while changing password';
    }
  }
}
