import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final _storage = const FlutterSecureStorage();
  Completer<bool>? _refreshCompleter;

  /// Dynamic Base URL:
  /// 1. Prioritizes API_BASE_URL defined in .env (e.g., LAN IP for physical device over Wi-Fi).
  /// 2. Android Emulator fallback: 10.0.2.2:8000/api
  /// 3. Desktop / Web fallback: 127.0.0.1:8000/api
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl.endsWith('/') ? envUrl.substring(0, envUrl.length - 1) : envUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api';
      }
    } catch (_) {
      // Fallback for non-supported platform query
    }
    return 'http://127.0.0.1:8000/api';
  }

  // ── Token Management ────────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'jwt_access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'jwt_refresh_token');
  }

  /// Backwards-compatible getter for existing calls
  Future<String?> getToken() async => await getAccessToken();

  Future<void> setTokens({required String access, String? refresh}) async {
    await _storage.write(key: 'jwt_access_token', value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: 'jwt_refresh_token', value: refresh);
    }
  }

  /// Backwards-compatible setter for single token
  Future<void> setToken(String token) async {
    await _storage.write(key: 'jwt_access_token', value: token);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'jwt_access_token');
    await _storage.delete(key: 'jwt_refresh_token');
  }

  Future<void> clearToken() async => await clearTokens();

  // ── Silent JWT Refresh Interceptor ──────────────────────────────────────────

  /// Silently refreshes access token using the stored refresh token.
  /// Deduplicates concurrent refresh attempts with a shared Completer.
  Future<bool> refreshToken() async {
    if (_refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refresh = await getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final url = Uri.parse('$baseUrl/auth/refresh/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'] as String?;
        final newRefresh = data['refresh'] as String?;

        if (newAccess != null) {
          await setTokens(access: newAccess, refresh: newRefresh);
          debugPrint('[ApiService] JWT Access Token silently refreshed.');
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      // Refresh failed or token was blacklisted/expired
      debugPrint('[ApiService] Refresh token expired or rejected. Clearing credentials.');
      await clearTokens();
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      debugPrint('[ApiService] Error during silent token refresh: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  // ── Intercepted HTTP Methods ────────────────────────────────────────────────

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    var response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        response = await http.get(url, headers: await _getHeaders());
      }
    }
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    var response = await http.post(url, headers: await _getHeaders(), body: jsonEncode(body));

    // Avoid recursive refresh if the login or refresh endpoint itself returns 401
    if (response.statusCode == 401 && !endpoint.contains('auth/')) {
      final refreshed = await refreshToken();
      if (refreshed) {
        response = await http.post(url, headers: await _getHeaders(), body: jsonEncode(body));
      }
    }
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    var response = await http.put(url, headers: await _getHeaders(), body: jsonEncode(body));

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        response = await http.put(url, headers: await _getHeaders(), body: jsonEncode(body));
      }
    }
    return response;
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    var response = await http.patch(url, headers: await _getHeaders(), body: jsonEncode(body));

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        response = await http.patch(url, headers: await _getHeaders(), body: jsonEncode(body));
      }
    }
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    var response = await http.delete(url, headers: await _getHeaders());

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        response = await http.delete(url, headers: await _getHeaders());
      }
    }
    return response;
  }
}

// Global singleton
final apiService = ApiService();
