import '../models/attendance_model.dart';

class TimetablePeriod {
  final String subject;
  final String code;
  final String room;
  final String type; // Theory or Lab
  final int startMinutes; // Minutes from midnight
  final int endMinutes;
  final String timeSlot;

  const TimetablePeriod({
    required this.subject,
    required this.code,
    required this.room,
    required this.type,
    required this.startMinutes,
    required this.endMinutes,
    required this.timeSlot,
  });
}

class NextClassInfo {
  final String cardHeader;
  final String badgeText;
  final String subjectName;
  final String slotInfo;
  final String timeSlot;
  final bool isCompleted;

  const NextClassInfo({
    required this.cardHeader,
    required this.badgeText,
    required this.subjectName,
    required this.slotInfo,
    required this.timeSlot,
    required this.isCompleted,
  });
}

class DynamicTimetableService {
  // Weekly timetable for Poornima College of Engineering (B.Tech CY / FY)
  static final Map<int, List<TimetablePeriod>> _weeklySchedule = {
    // 1: Monday
    DateTime.monday: [
      const TimetablePeriod(subject: 'Engineering Mathematics-I', code: 'PC261FY103', room: 'NB-304', type: 'Theory', startMinutes: 480, endMinutes: 540, timeSlot: '08:00 AM - 09:00 AM'),
      const TimetablePeriod(subject: 'Human Values and Ethics', code: 'PC261FY405', room: 'NB-201', type: 'Theory', startMinutes: 540, endMinutes: 600, timeSlot: '09:00 AM - 10:00 AM'),
      const TimetablePeriod(subject: 'Basic Electrical Engineering', code: 'PC261CY104', room: 'NB-201', type: 'Theory', startMinutes: 600, endMinutes: 660, timeSlot: '10:00 AM - 11:00 AM'),
      const TimetablePeriod(subject: 'Engineering Physics', code: 'PC261FY102', room: 'NB-302', type: 'Theory', startMinutes: 660, endMinutes: 720, timeSlot: '11:00 AM - 12:00 PM'),
      const TimetablePeriod(subject: 'Engineering Physics Lab', code: 'PC261FY122', room: 'PhyLab-2', type: 'Lab', startMinutes: 770, endMinutes: 830, timeSlot: '12:50 PM - 01:50 PM'),
      const TimetablePeriod(subject: 'Engineering Physics Lab', code: 'PC261FY122', room: 'PhyLab-2', type: 'Lab', startMinutes: 830, endMinutes: 890, timeSlot: '01:50 PM - 02:50 PM'),
    ],
    // 2: Tuesday
    DateTime.tuesday: [
      const TimetablePeriod(subject: 'Basic Electrical Engineering', code: 'PC261CY104', room: 'NB-201', type: 'Theory', startMinutes: 480, endMinutes: 540, timeSlot: '08:00 AM - 09:00 AM'),
      const TimetablePeriod(subject: 'Engineering Mathematics-I', code: 'PC261FY103', room: 'NB-304', type: 'Theory', startMinutes: 540, endMinutes: 600, timeSlot: '09:00 AM - 10:00 AM'),
      const TimetablePeriod(subject: 'Programming with C', code: 'PC261FY106', room: 'CSLab-1', type: 'Theory', startMinutes: 600, endMinutes: 660, timeSlot: '10:00 AM - 11:00 AM'),
      const TimetablePeriod(subject: 'Human Values and Ethics', code: 'PC261FY405', room: 'NB-201', type: 'Theory', startMinutes: 660, endMinutes: 720, timeSlot: '11:00 AM - 12:00 PM'),
      const TimetablePeriod(subject: 'Programming with C Lab', code: 'PC261FY123', room: 'CSLab-3', type: 'Lab', startMinutes: 770, endMinutes: 830, timeSlot: '12:50 PM - 01:50 PM'),
      const TimetablePeriod(subject: 'Programming with C Lab', code: 'PC261FY123', room: 'CSLab-3', type: 'Lab', startMinutes: 830, endMinutes: 890, timeSlot: '01:50 PM - 02:50 PM'),
    ],
    // 3: Wednesday
    DateTime.wednesday: [
      const TimetablePeriod(subject: 'Engineering Physics', code: 'PC261FY102', room: 'NB-302', type: 'Theory', startMinutes: 480, endMinutes: 540, timeSlot: '08:00 AM - 09:00 AM'),
      const TimetablePeriod(subject: 'Engineering Mathematics-I', code: 'PC261FY103', room: 'NB-304', type: 'Theory', startMinutes: 540, endMinutes: 600, timeSlot: '09:00 AM - 10:00 AM'),
      const TimetablePeriod(subject: 'Language Lab*', code: 'PC261FY526', room: 'LangLab', type: 'Lab', startMinutes: 600, endMinutes: 660, timeSlot: '10:00 AM - 11:00 AM'),
      const TimetablePeriod(subject: 'Language Lab*', code: 'PC261FY526', room: 'LangLab', type: 'Lab', startMinutes: 660, endMinutes: 720, timeSlot: '11:00 AM - 12:00 PM'),
      const TimetablePeriod(subject: 'IDEA Lab Workshop', code: 'PC261FY628', room: 'IDEA Lab', type: 'Lab', startMinutes: 770, endMinutes: 830, timeSlot: '12:50 PM - 01:50 PM'),
      const TimetablePeriod(subject: 'IDEA Lab Workshop', code: 'PC261FY628', room: 'IDEA Lab', type: 'Lab', startMinutes: 830, endMinutes: 890, timeSlot: '01:50 PM - 02:50 PM'),
    ],
    // 4: Thursday
    DateTime.thursday: [
      const TimetablePeriod(subject: 'Human Values and Ethics', code: 'PC261FY405', room: 'NB-201', type: 'Theory', startMinutes: 480, endMinutes: 540, timeSlot: '08:00 AM - 09:00 AM'),
      const TimetablePeriod(subject: 'Basic Electrical Engineering', code: 'PC261CY104', room: 'NB-201', type: 'Theory', startMinutes: 540, endMinutes: 600, timeSlot: '09:00 AM - 10:00 AM'),
      const TimetablePeriod(subject: 'Engineering Mathematics-I', code: 'PC261FY103', room: 'NB-304', type: 'Theory', startMinutes: 600, endMinutes: 660, timeSlot: '10:00 AM - 11:00 AM'),
      const TimetablePeriod(subject: 'Human Values and Ethics', code: 'PC261FY405', room: 'NB-201', type: 'Theory', startMinutes: 660, endMinutes: 720, timeSlot: '11:00 AM - 12:00 PM'),
      const TimetablePeriod(subject: 'Web Programming Lab', code: 'PC261CY124', room: 'Lab-4', type: 'Lab', startMinutes: 770, endMinutes: 830, timeSlot: '12:50 PM - 01:50 PM'),
      const TimetablePeriod(subject: 'Web Programming Lab', code: 'PC261CY124', room: 'Lab-4', type: 'Lab', startMinutes: 830, endMinutes: 890, timeSlot: '01:50 PM - 02:50 PM'),
    ],
    // 5: Friday
    DateTime.friday: [
      const TimetablePeriod(subject: 'Engineering Mathematics-I', code: 'PC261FY103', room: 'NB-304', type: 'Theory', startMinutes: 480, endMinutes: 540, timeSlot: '08:00 AM - 09:00 AM'),
      const TimetablePeriod(subject: 'Programming with C', code: 'PC261FY106', room: 'CSLab-1', type: 'Theory', startMinutes: 540, endMinutes: 600, timeSlot: '09:00 AM - 10:00 AM'),
      const TimetablePeriod(subject: 'Basic Electrical Engineering', code: 'PC261CY104', room: 'NB-201', type: 'Theory', startMinutes: 600, endMinutes: 660, timeSlot: '10:00 AM - 11:00 AM'),
      const TimetablePeriod(subject: 'Engineering Physics', code: 'PC261FY102', room: 'NB-302', type: 'Theory', startMinutes: 660, endMinutes: 720, timeSlot: '11:00 AM - 12:00 PM'),
      const TimetablePeriod(subject: 'Manufacturing Practices Workshop', code: 'PC261FY629', room: 'Workshop', type: 'Lab', startMinutes: 770, endMinutes: 830, timeSlot: '12:50 PM - 01:50 PM'),
      const TimetablePeriod(subject: 'Manufacturing Practices Workshop', code: 'PC261FY629', room: 'Workshop', type: 'Lab', startMinutes: 830, endMinutes: 890, timeSlot: '01:50 PM - 02:50 PM'),
    ],
    // 6: Saturday
    DateTime.saturday: [
      const TimetablePeriod(subject: 'Non Syllabus Project (NSP)', code: 'NSP001', room: 'Innovation Hub', type: 'Lab', startMinutes: 480, endMinutes: 540, timeSlot: '08:00 AM - 09:00 AM'),
      const TimetablePeriod(subject: 'Non Syllabus Project (NSP)', code: 'NSP001', room: 'Innovation Hub', type: 'Lab', startMinutes: 540, endMinutes: 600, timeSlot: '09:00 AM - 10:00 AM'),
      const TimetablePeriod(subject: 'Engineering Mathematics-I Tutorial', code: 'PC261FY103', room: 'NB-304', type: 'Theory', startMinutes: 600, endMinutes: 660, timeSlot: '10:00 AM - 11:00 AM'),
      const TimetablePeriod(subject: 'Human Values and Ethics', code: 'PC261FY405', room: 'NB-201', type: 'Theory', startMinutes: 660, endMinutes: 720, timeSlot: '11:00 AM - 12:00 PM'),
    ],
  };

  /// Returns periods for the current day with dynamic status computed from real clock
  static List<PeriodSlot> getDynamicPeriodsForToday() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final currentMinutes = now.hour * 60 + now.minute;

    if (weekday == DateTime.sunday) {
      return [
        PeriodSlot(
          subject: 'Sunday Holiday • No Lectures',
          timeSlot: 'All Day',
          status: 'Weekend',
        ),
      ];
    }

    final schedule = _weeklySchedule[weekday] ?? _weeklySchedule[DateTime.thursday]!;
    final List<PeriodSlot> slots = [];

    for (final p in schedule) {
      String status;
      if (currentMinutes < p.startMinutes) {
        status = 'Upcoming';
      } else if (currentMinutes >= p.startMinutes && currentMinutes < p.endMinutes) {
        status = 'In Progress';
      } else {
        status = 'Completed';
      }

      slots.add(PeriodSlot(
        subject: p.subject,
        timeSlot: p.timeSlot,
        status: status,
      ));
    }

    return slots;
  }

  /// Calculates real-time Next Class overview for Dashboard card
  static NextClassInfo getNextClassOverview() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final currentMinutes = now.hour * 60 + now.minute;

    // Sunday Handling
    if (weekday == DateTime.sunday) {
      return const NextClassInfo(
        cardHeader: 'Weekend',
        badgeText: 'Sunday Off',
        subjectName: 'No Classes Today',
        slotInfo: 'Campus Closed • College resumes Monday',
        timeSlot: 'Monday 08:00 AM',
        isCompleted: true,
      );
    }

    final schedule = _weeklySchedule[weekday] ?? _weeklySchedule[DateTime.thursday]!;

    // 1. Before First Period (< 8:00 AM)
    if (currentMinutes < schedule.first.startMinutes) {
      final minsUntil = schedule.first.startMinutes - currentMinutes;
      final hoursUntil = minsUntil ~/ 60;
      final minsRemaining = minsUntil % 60;
      final badge = hoursUntil > 0 ? 'Starts in ${hoursUntil}h ${minsRemaining}m' : 'Starts in ${minsRemaining}m';

      return NextClassInfo(
        cardHeader: 'First Class Today',
        badgeText: badge,
        subjectName: schedule.first.subject,
        slotInfo: '${schedule.first.room} • ${schedule.first.type}',
        timeSlot: schedule.first.timeSlot.split(' - ').first,
        isCompleted: false,
      );
    }

    // 2. Active College Hours (8:00 AM - 2:50 PM)
    for (int i = 0; i < schedule.length; i++) {
      final p = schedule[i];

      // Currently inside this class
      if (currentMinutes >= p.startMinutes && currentMinutes < p.endMinutes) {
        final remainingMins = p.endMinutes - currentMinutes;
        return NextClassInfo(
          cardHeader: 'Class In Session',
          badgeText: '${remainingMins}m remaining',
          subjectName: p.subject,
          slotInfo: '${p.room} • ${p.type}',
          timeSlot: p.timeSlot,
          isCompleted: false,
        );
      }

      // Between classes or during lunch
      if (currentMinutes < p.startMinutes) {
        final minsUntil = p.startMinutes - currentMinutes;
        return NextClassInfo(
          cardHeader: 'Next Class',
          badgeText: 'Starts in ${minsUntil}m',
          subjectName: p.subject,
          slotInfo: '${p.room} • ${p.type}',
          timeSlot: p.timeSlot.split(' - ').first,
          isCompleted: false,
        );
      }
    }

    // 3. College Day Over (> 2:50 PM / Evening / Night)
    final tomorrowWeekday = weekday == DateTime.saturday ? DateTime.monday : (weekday + 1);
    final tomorrowDayName = weekday == DateTime.saturday ? 'Monday' : 'Tomorrow';
    final tomorrowFirstPeriod = _weeklySchedule[tomorrowWeekday]?.first;

    return NextClassInfo(
      cardHeader: 'All Classes Done',
      badgeText: 'Day Complete',
      subjectName: 'No more lectures today',
      slotInfo: 'Next: ${tomorrowFirstPeriod?.subject ?? "Classes"} @ 08:00 AM',
      timeSlot: tomorrowDayName,
      isCompleted: true,
    );
  }
}
