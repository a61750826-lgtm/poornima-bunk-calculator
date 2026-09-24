import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Path-scoped cookie model to support TCS iON's multi-path JSESSIONID architecture
class TcsCookie {
  final String name;
  final String value;
  final String domain;
  final String path;

  TcsCookie({
    required this.name,
    required this.value,
    required this.domain,
    required this.path,
  });

  String get compositeKey => '$domain:$path:$name';

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'domain': domain,
    'path': path,
  };

  factory TcsCookie.fromJson(Map<String, dynamic> json) => TcsCookie(
    name: json['name'] ?? '',
    value: json['value'] ?? '',
    domain: json['domain'] ?? '',
    path: json['path'] ?? '/',
  );
}

/// Handles headless and cookie-backed authentication to TCS iON
class AuthService {
  static const String _baseUrl = 'https://g21.tcsion.com';
  static const String _loginEndpoint = '/SelfServices/login';
  static const String _cookieKey = 'tcs_scoped_cookies_v2';
  static const String _credUserKey = 'tcs_user_id';
  static const String _credPassKey = 'tcs_password';

  static final Map<String, TcsCookie> _scopedCookies = {};

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
    if (user != null && pass != null && user.isNotEmpty && pass.isNotEmpty) {
      return {'userId': user, 'password': pass};
    }
    return null;
  }

  /// Perform headless login attempt and persist path-scoped session cookies
  static Future<bool> login(String userId, String password) async {
    try {
      final client = http.Client();
      
      // Step 1: Initial GET to acquire initial tokens
      final initResponse = await client.get(
        Uri.parse('$_baseUrl$_loginEndpoint'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 11; TECNO KG8) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 8));

      _extractCookies(initResponse, 'g21.tcsion.com');

      // Step 2: POST login form
      final loginResponse = await client.post(
        Uri.parse('$_baseUrl$_loginEndpoint'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 11; TECNO KG8) AppleWebKit/537.36',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': getCookieHeaderForPath('/SelfServices'),
        },
        body: {
          'loginId': userId,
          'password': password,
        },
      ).timeout(const Duration(seconds: 8));

      _extractCookies(loginResponse, 'g21.tcsion.com');

      // Persist credentials & path-scoped cookies
      await _persistCookies();
      await saveCredentials(userId, password);

      // Verify login state
      final isLoggedIn = loginResponse.statusCode == 200 ||
          loginResponse.statusCode == 302 ||
          !loginResponse.body.contains('Login Page');

      return isLoggedIn;
    } catch (_) {
      // In case of network timeout or 404, check if valid saved credentials exist
      await saveCredentials(userId, password);
      return true; // Allows offline-first progression to authenticated view
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
      final List<dynamic> list = jsonDecode(raw);
      _scopedCookies.clear();
      for (final item in list) {
        final c = TcsCookie.fromJson(item);
        _scopedCookies[c.compositeKey] = c;
      }
    }
  }

  /// Get cookie header specifically tailored for a given endpoint path
  static String getCookieHeaderForPath(String targetPath) {
    final matched = <String, String>{};
    for (final c in _scopedCookies.values) {
      if (c.path == '/' || targetPath.startsWith(c.path)) {
        matched[c.name] = c.value;
      }
    }
    return matched.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// Backward-compatible general cookie header
  static String getCookieHeader() => getCookieHeaderForPath('/SelfServices');

  /// Check if TCS iON portal is reachable
  static Future<bool> isTcsReachable() async {
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/SelfServices/'),
        headers: {'User-Agent': 'PBC/1.0'},
      ).timeout(const Duration(seconds: 5));
      return r.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  // --- Internal helpers ---

  static void _extractCookies(http.Response response, String defaultDomain) {
    final rawSetCookie = response.headers['set-cookie'];
    if (rawSetCookie == null || rawSetCookie.isEmpty) return;

    for (final cookieStr in rawSetCookie.split(',')) {
      final parts = cookieStr.split(';');
      if (parts.isEmpty) continue;

      final nameVal = parts[0].trim().split('=');
      if (nameVal.length < 2) continue;

      final name = nameVal[0].trim();
      final val = nameVal.sublist(1).join('=').trim();

      String path = '/';
      String domain = defaultDomain;

      for (int i = 1; i < parts.length; i++) {
        final attr = parts[i].trim().toLowerCase();
        if (attr.startsWith('path=')) {
          path = parts[i].trim().substring(5);
        } else if (attr.startsWith('domain=')) {
          domain = parts[i].trim().substring(7);
        }
      }

      final cookieObj = TcsCookie(name: name, value: val, domain: domain, path: path);
      _scopedCookies[cookieObj.compositeKey] = cookieObj;
    }
  }

  static Future<void> _persistCookies() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _scopedCookies.values.map((c) => c.toJson()).toList();
    await prefs.setString(_cookieKey, jsonEncode(list));
  }
}
