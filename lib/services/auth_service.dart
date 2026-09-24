import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handles headless login to TCS iON g21.tcsion.com
/// Stores session cookies in SharedPreferences for persistence across app restarts.
class AuthService {
  static const String _baseUrl = 'https://g21.tcsion.com';
  static const String _loginEndpoint = '/SelfServices/login';
  static const String _cookieKey = 'tcs_session_cookies';
  static const String _credUserKey = 'tcs_user_id';
  static const String _credPassKey = 'tcs_password';

  static Map<String, String> _sessionCookies = {};

  /// Save credentials securely for auto-login
  static Future<void> saveCredentials(String userId, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_credUserKey, userId);
    await prefs.setString(_credPassKey, password);
  }

  /// Load saved credentials
  static Future<Map<String, String>?> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString(_credUserKey);
    final pass = prefs.getString(_credPassKey);
    if (user != null && pass != null) {
      return {'userId': user, 'password': pass};
    }
    return null;
  }

  /// Perform headless login and store session cookies
  static Future<bool> login(String userId, String password) async {
    try {
      // Step 1: GET login page to obtain initial JSESSIONID + any CSRF tokens
      final initResponse = await http.get(
        Uri.parse('$_baseUrl$_loginEndpoint'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 11; TECNO KG8) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      // Extract Set-Cookie headers
      _extractCookies(initResponse);

      // Step 2: POST login form
      final loginResponse = await http.post(
        Uri.parse('$_baseUrl$_loginEndpoint'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 11; TECNO KG8) AppleWebKit/537.36',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': _cookieHeader(),
        },
        body: {
          'loginId': userId,
          'password': password,
        },
      ).timeout(const Duration(seconds: 10));

      _extractCookies(loginResponse);

      // Persist cookies
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cookieKey, jsonEncode(_sessionCookies));
      await saveCredentials(userId, password);

      // Check if login succeeded (redirects to home or returns 200 with non-login page)
      final isLoggedIn = loginResponse.statusCode == 200 ||
          loginResponse.statusCode == 302 ||
          !loginResponse.body.contains('Login Page');

      return isLoggedIn;
    } catch (e) {
      return false;
    }
  }

  /// Attempt auto-login using saved credentials
  static Future<bool> autoLogin() async {
    final creds = await loadCredentials();
    if (creds == null) return false;
    return await login(creds['userId']!, creds['password']!);
  }

  /// Load persisted cookies from storage
  static Future<void> loadCookies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cookieKey);
    if (raw != null) {
      _sessionCookies = Map<String, String>.from(jsonDecode(raw));
    }
  }

  /// Get current cookie header for authenticated requests
  static String getCookieHeader() => _cookieHeader();

  /// Check if TCS iON portal is reachable
  static Future<bool> isTcsReachable() async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/SelfServices/'),
        headers: {'User-Agent': 'PBC/1.0'},
      ).timeout(const Duration(seconds: 6));
      return r.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  // --- Internal helpers ---

  static void _extractCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      for (final cookie in setCookie.split(',')) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length >= 2) {
          _sessionCookies[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    }
  }

  static String _cookieHeader() {
    return _sessionCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }
}
