import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService {
  Future<Map<String, String>> login(String email, String password, [String? role]) async {
    try {
      debugPrint('Attempting login with Django API');
      
      final response = await apiService.post('auth/login/', {
        'username': email, // Using email as username for simplicity, or change backend
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access'];
        final refreshToken = data['refresh'];
        
        await apiService.setTokens(access: token, refresh: refreshToken);
        
        // Fetch user profile to check role
        final userResponse = await apiService.get('users/me/');
        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          final actualRole = userData['role'] ?? 'user';
          
          if (role != null && role.isNotEmpty && actualRole != role) {
            await apiService.clearTokens();
            if (role == 'admin') {
              throw Exception('This account is not registered as an admin');
            } else {
              throw Exception('Admin accounts cannot log in through the user gateway');
            }
          }
          
          _currentUserData = userData;
          
          debugPrint('====== LOGIN SUCCESS ======');
          debugPrint('User ID: ${userData['id']}');
          debugPrint('Requested Role: $role');
          debugPrint('===========================');
          
          return {
            'token': token,
            'role': actualRole, 
          };
        } else {
          await apiService.clearTokens();
          throw Exception('Failed to fetch user profile');
        }
      } else {
        throw Exception('Invalid email or password');
      }
    } catch (e) {
      debugPrint('AuthService Error: $e');
      throw Exception('Verification Error: $e');
    }
  }
  
  Future<Map<String, String>> signup(String email, String password, String role, String major) async {
    try {
      debugPrint('Attempting signup with Django API');
      
      final response = await apiService.post('users/register/', {
        'username': email,
        'email': email,
        'password': password,
        'role': role,
        'major': major,
      });

      if (response.statusCode == 201) {
        // Automatically login after signup
        return await login(email, password, role);
      } else {
        throw Exception('Signup failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('AuthService Signup Error: $e');
      throw Exception('Registration Error: $e');
    }
  }

  Map<String, dynamic>? _currentUserData;

  Map<String, dynamic>? get currentUserData => _currentUserData;
  String? get currentUserId => _currentUserData?['id']?.toString();
  String? get currentUserEmail => _currentUserData?['email'];
  String? get currentUserName => _currentUserData?['username'];
  String? get currentUserRole => _currentUserData?['role'];
  String? get currentUserMajor => _currentUserData?['major'];

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUserData != null) return _currentUserData;
    final token = await apiService.getToken();
    if (token == null) return null;
    try {
      final userResponse = await apiService.get('users/me/');
      if (userResponse.statusCode == 200) {
        _currentUserData = jsonDecode(userResponse.body);
        return _currentUserData;
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
    return null;
  }

  Future<void> logout() async {
    _currentUserData = null;
    await apiService.clearTokens();
  }
}

final authService = AuthService();
