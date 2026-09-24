import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

class SchedulerService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  // 1. Morning 7:30 AM Digest Alert
  static Future<void> showMorningDigest({
    required int periodCount,
    required String firstSubject,
    required String firstTime,
    required int safeBunks,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'poornima_morning_digest',
      'Morning Digest',
      channelDescription: 'Daily 7:30 AM schedule & bunk buffer alert',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notifications.show(
      1001,
      'Good morning, Gaurav! ☀️',
      'Today: $periodCount periods (First: $firstSubject @ $firstTime). Bunk Wallet: +$safeBunks safe leaves.',
      const NotificationDetails(android: androidDetails),
    );
  }

  // 2. Post-Class Attendance Mark Alert
  static Future<void> showAttendanceUpdated({
    required String subject,
    required String status,
    required double newPercentage,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'poornima_attendance_updates',
      'Attendance Alerts',
      channelDescription: 'Immediate notifications after each lecture ends',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notifications.show(
      1002,
      'Attendance Marked: $status',
      '$subject has been marked as $status. Overall: ${newPercentage.toStringAsFixed(1)}%',
      const NotificationDetails(android: androidDetails),
    );
  }
}
