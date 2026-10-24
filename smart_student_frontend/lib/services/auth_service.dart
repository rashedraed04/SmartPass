import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  Future<Map<String, String>> login(String email, String password, [String? role]) async {
    try {
      debugPrint('Attempting login with Django API');

      final response = await apiService.post('auth/login/', {
        'username': email, // Using email as username for simplicity, or change backend
        'password': password,
      });

      if (response.statusCode == 200) {
        return await _finishLogin(jsonDecode(response.body), role);
      } else {
        throw Exception('Invalid email or password');
      }
    } catch (e) {
      debugPrint('AuthService Error: $e');
      throw Exception('Verification Error: $e');
    }
  }

  /// Signs in with Google and exchanges the Google ID token for this API's JWTs.
  /// Returns null if the user closes the account picker.
  Future<Map<String, String>?> loginWithGoogle() async {
    try {
      debugPrint('Attempting Google login with Django API');

      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      // Issued for the web OAuth client in android/app/google-services.json,
      // which is the audience the backend checks.
      final idToken = (await account.authentication).idToken;
      if (idToken == null) {
        throw Exception('Google did not return an ID token');
      }

      final response = await apiService.post('auth/google/', {'id_token': idToken});
      if (response.statusCode != 200) {
        throw Exception(_errorMessage(response.body, 'Google sign-in failed'));
      }
      return await _finishLogin(jsonDecode(response.body), null);
    } catch (e) {
      debugPrint('AuthService Google Error: $e');
      // Forget the Google account so the next attempt shows the account picker again.
      await _signOutOfGoogle();
      throw Exception('Google Sign-In Error: $e');
    }
  }

  /// Stores the JWT pair from a login response and loads the user's profile.
  Future<Map<String, String>> _finishLogin(Map<String, dynamic> data, String? role) async {
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
  }

  String _errorMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      if (data is Map) return (data['error'] ?? data['detail'] ?? fallback).toString();
    } catch (_) {
      // Not JSON, use the fallback.
    }
    return fallback;
  }

  Future<void> _signOutOfGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google Sign-In isn't available on this platform (e.g. desktop).
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
    await _signOutOfGoogle();
  }
}

final authService = AuthService();
