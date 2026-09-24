import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';
import 'auth_service.dart';

/// Fetches and parses attendance data from TCS iON SelfServices portal.
/// Works headlessly using stored session cookies from AuthService.
class ScraperService {
  static const String _baseUrl = 'https://g21.tcsion.com';
  static const String _cacheKey = 'attendance_cache_json';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _tcsStatusKey = 'tcs_is_down';

  /// Primary fetch: attempts live scrape, falls back to cache on failure.
  static Future<AttendanceReport?> fetchAttendance() async {
    try {
      // Ensure we have cookies
      await AuthService.loadCookies();
      final cookie = AuthService.getCookieHeader();

      if (cookie.isEmpty) {
        // Try auto-login
        final loggedIn = await AuthService.autoLogin();
        if (!loggedIn) return await _loadFromCache();
      }

      // Fetch SelfServices home (contains attendance data or links to it)
      final response = await http.get(
        Uri.parse('$_baseUrl/SelfServices/home'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 11; TECNO KG8) AppleWebKit/537.36',
          'Cookie': AuthService.getCookieHeader(),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 500) {
        await _setTcsDown(true);
        return await _loadFromCache();
      }

      await _setTcsDown(false);

      // Parse the HTML response for attendance data
      final report = _parseAttendanceHtml(response.body);
      if (report != null) {
        await _saveToCache(report);
      }
      return report ?? await _loadFromCache();
    } catch (e) {
      await _setTcsDown(true);
      return await _loadFromCache();
    }
  }

  /// Parse attendance HTML table from TCS iON response
  static AttendanceReport? _parseAttendanceHtml(String html) {
    try {
      // TCS iON uses server-rendered tables; we parse key data patterns
      // This parser handles the SelfServices attendance summary page

      final subjects = <Subject>[];
      final schedule = <PeriodSlot>[];

      // Extract subject rows using regex patterns
      // Pattern: Subject Name, Code, Total, Present, Absent, %
      final subjectPattern = RegExp(
        r'<td[^>]*>(.*?)</td>\s*<td[^>]*>(PC261\w+|NSP\d+)</td>\s*<td[^>]*>(\d+)</td>\s*<td[^>]*>(\d+)</td>\s*<td[^>]*>(\d+)</td>\s*<td[^>]*>([\d.]+)%?</td>',
        dotAll: true,
      );

      for (final match in subjectPattern.allMatches(html)) {
        final name = _stripHtml(match.group(1) ?? '');
        final code = match.group(2) ?? '';
        final total = int.tryParse(match.group(3) ?? '0') ?? 0;
        final present = int.tryParse(match.group(4) ?? '0') ?? 0;
        final absent = int.tryParse(match.group(5) ?? '0') ?? 0;
        final pct = double.tryParse(match.group(6) ?? '0') ?? 0.0;

        final safeBunks = total > 0 ? max(0, (present / 0.75).floor() - total) : 0;
        final needToAttend = pct < 75.0 && total > 0
            ? max(1, ((0.75 * total - present) / 0.25).ceil())
            : 0;

        subjects.add(Subject(
          code: code,
          name: name,
          total: total,
          present: present,
          absent: absent,
          percentage: pct,
          safeBunks: safeBunks,
          needToAttend: needToAttend,
        ));
      }

      // Calculate overall stats
      int overallTotal = 0, overallPresent = 0, overallAbsent = 0;
      for (final s in subjects) {
        overallTotal += s.total;
        overallPresent += s.present;
        overallAbsent += s.absent;
      }
      final overallPct = overallTotal > 0
          ? double.parse(((overallPresent / overallTotal) * 100).toStringAsFixed(2))
          : 0.0;
      final totalSafeBunks = overallTotal > 0
          ? max(0, (overallPresent / 0.75).floor() - overallTotal)
          : 0;

      String bunkAdvice;
      if (overallPct >= 75.0) {
        bunkAdvice = 'You can safely miss up to $totalSafeBunks class(es) and remain above 75%.';
      } else {
        final need = max(1, ((0.75 * overallTotal - overallPresent) / 0.25).ceil());
        bunkAdvice = 'You must attend the next $need consecutive class(es) to cross 75%.';
      }

      // If no subjects matched, parsing failed (e.g. redirected to login or portal changed structure)
      if (subjects.isEmpty) {
        return null;
      }

      final now = DateTime.now();
      final dateStr = '${now.day}-${_monthName(now.month)}-${now.year}';

      return AttendanceReport(
        appName: 'Poornima Bunk Calculator',
        developer: 'Crafted with precision by Gourav Singh (cyber)',
        studentName: 'Gaurav',
        program: 'B. Tech. (CY) PCE (Semester 1)',
        overallTotal: overallTotal,
        overallPresent: overallPresent,
        overallAbsent: overallAbsent,
        overallPercentage: overallPct,
        totalSafeBunks: totalSafeBunks,
        bunkAdvice: bunkAdvice,
        isTcsDown: false,
        lastSyncedAt: '${now.hour}:${now.minute.toString().padLeft(2, '0')} ${dateStr}',
        date: dateStr,
        subjects: subjects,
        todaySchedule: schedule,
      );
    } catch (e) {
      return null;
    }
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  // --- Cache layer ---

  static Future<void> _saveToCache(AttendanceReport report) async {
    final prefs = await SharedPreferences.getInstance();
    // Serialize manually since we don't have toJson
    final map = {
      'app_name': report.appName,
      'developer': report.developer,
      'student_name': report.studentName,
      'program': report.program,
      'overall_total': report.overallTotal,
      'overall_present': report.overallPresent,
      'overall_absent': report.overallAbsent,
      'overall_percentage': report.overallPercentage,
      'total_safe_bunks': report.totalSafeBunks,
      'bunk_advice': report.bunkAdvice,
      'is_tcs_down': report.isTcsDown,
      'last_synced_at': report.lastSyncedAt,
      'date': report.date,
      'subjects': report.subjects.map((s) => {
        'code': s.code, 'name': s.name, 'total': s.total,
        'present': s.present, 'absent': s.absent, 'percentage': s.percentage,
        'safe_bunks': s.safeBunks, 'need_to_attend': s.needToAttend,
      }).toList(),
      'today_schedule': report.todaySchedule.map((p) => {
        'subject': p.subject, 'time_slot': p.timeSlot, 'status': p.status,
      }).toList(),
    };
    await prefs.setString(_cacheKey, jsonEncode(map));
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  static Future<AttendanceReport?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final isTcsDown = prefs.getBool(_tcsStatusKey) ?? false;
      map['is_tcs_down'] = isTcsDown;
      if (isTcsDown) {
        final lastSync = prefs.getString(_lastSyncKey) ?? 'Unknown';
        map['last_synced_at'] = 'Offline since $lastSync';
      }
      return AttendanceReport.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _setTcsDown(bool isDown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tcsStatusKey, isDown);
  }
}
