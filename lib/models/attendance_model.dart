class Subject {
  final String code;
  final String name;
  final int total;
  final int present;
  final int absent;
  final double percentage;
  final int safeBunks;
  final int needToAttend;

  Subject({
    required this.code,
    required this.name,
    required this.total,
    required this.present,
    required this.absent,
    required this.percentage,
    required this.safeBunks,
    required this.needToAttend,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      total: json['total'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      safeBunks: json['safe_bunks'] ?? 0,
      needToAttend: json['need_to_attend'] ?? 0,
    );
  }
}

class PeriodSlot {
  final String subject;
  final String timeSlot;
  final String status;

  PeriodSlot({
    required this.subject,
    required this.timeSlot,
    required this.status,
  });

  factory PeriodSlot.fromJson(Map<String, dynamic> json) {
    return PeriodSlot(
      subject: json['subject'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      status: json['status'] ?? 'Pending',
    );
  }
}

class AttendanceReport {
  final String appName;
  final String developer;
  final String studentName;
  final String program;
  final int overallTotal;
  final int overallPresent;
  final int overallAbsent;
  final double overallPercentage;
  final int totalSafeBunks;
  final String bunkAdvice;
  final bool isTcsDown;
  final String lastSyncedAt;
  final String date;
  final List<Subject> subjects;
  final List<PeriodSlot> todaySchedule;

  AttendanceReport({
    required this.appName,
    required this.developer,
    required this.studentName,
    required this.program,
    required this.overallTotal,
    required this.overallPresent,
    required this.overallAbsent,
    required this.overallPercentage,
    required this.totalSafeBunks,
    required this.bunkAdvice,
    required this.isTcsDown,
    required this.lastSyncedAt,
    required this.date,
    required this.subjects,
    required this.todaySchedule,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    var subjs = (json['subjects'] as List? ?? [])
        .map((s) => Subject.fromJson(s))
        .toList();
    var schedule = (json['today_schedule'] as List? ?? [])
        .map((p) => PeriodSlot.fromJson(p))
        .toList();

    return AttendanceReport(
      appName: json['app_name'] ?? 'Poornima Bunk Calculator',
      developer: json['developer'] ?? 'Crafted with precision by Gourav Singh (cyber)',
      studentName: json['student_name'] ?? 'Gaurav',
      program: json['program'] ?? 'B. Tech. (CY) PCE (Semester 1)',
      overallTotal: json['overall_total'] ?? 0,
      overallPresent: json['overall_present'] ?? 0,
      overallAbsent: json['overall_absent'] ?? 0,
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble() ?? 0.0,
      totalSafeBunks: json['total_safe_bunks'] ?? 0,
      bunkAdvice: json['bunk_advice'] ?? '',
      isTcsDown: json['is_tcs_down'] ?? false,
      lastSyncedAt: json['last_synced_at'] ?? '',
      date: json['date'] ?? '',
      subjects: subjs,
      todaySchedule: schedule,
    );
  }
}
