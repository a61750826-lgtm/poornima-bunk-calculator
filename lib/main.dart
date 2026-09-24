import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/attendance_model.dart';

void main() {
  runApp(const PoornimaBunkApp());
}

class PoornimaBunkApp extends StatelessWidget {
  const PoornimaBunkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poornima Bunk Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080B10),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Pre-loaded verified report state
  final report = AttendanceReport(
    appName: 'Poornima Bunk Calculator',
    developer: 'Crafted with precision by Gourav Singh (cyber)',
    studentName: 'Gaurav',
    program: 'B. Tech. (CY) PCE (Semester 1)',
    overallTotal: 72,
    overallPresent: 69,
    overallAbsent: 3,
    overallPercentage: 95.83,
    totalSafeBunks: 20,
    bunkAdvice: 'You can safely miss up to 20 class(es) and remain comfortably above 75%.',
    isTcsDown: false,
    lastSyncedAt: '24-Sep-2026 23:40',
    date: '24-September-2026',
    subjects: [
      Subject(code: 'NSP001', name: 'Non Syllabus Project', total: 6, present: 6, absent: 0, percentage: 100.0, safeBunks: 2, needToAttend: 0),
      Subject(code: 'PC261FY103', name: 'Engineering Mathematics-I', total: 12, present: 12, absent: 0, percentage: 100.0, safeBunks: 4, needToAttend: 0),
      Subject(code: 'PC261CY104', name: 'Basic Electrical & Electronics Engg', total: 9, present: 7, absent: 2, percentage: 77.78, safeBunks: 0, needToAttend: 0),
      Subject(code: 'PC261FY102', name: 'Engineering Physics', total: 6, present: 5, absent: 1, percentage: 83.33, safeBunks: 0, needToAttend: 0),
      Subject(code: 'PC261FY106', name: 'Programming with C', total: 3, present: 3, absent: 0, percentage: 100.0, safeBunks: 1, needToAttend: 0),
      Subject(code: 'PC261FY405', name: 'Human Values and Ethics', total: 10, present: 10, absent: 0, percentage: 100.0, safeBunks: 3, needToAttend: 0),
      Subject(code: 'PC261CY124', name: 'Web Programming Lab', total: 6, present: 6, absent: 0, percentage: 100.0, safeBunks: 2, needToAttend: 0),
      Subject(code: 'PC261FY122', name: 'Engineering Physics Lab', total: 4, present: 4, absent: 0, percentage: 100.0, safeBunks: 1, needToAttend: 0),
      Subject(code: 'PC261FY123', name: 'Programming with C Lab', total: 2, present: 2, absent: 0, percentage: 100.0, safeBunks: 0, needToAttend: 0),
      Subject(code: 'PC261FY526', name: 'Language Lab*', total: 6, present: 6, absent: 0, percentage: 100.0, safeBunks: 2, needToAttend: 0),
      Subject(code: 'PC261FY628', name: 'IDEA Lab Workshop', total: 2, present: 2, absent: 0, percentage: 100.0, safeBunks: 0, needToAttend: 0),
      Subject(code: 'PC261FY629', name: 'Manufacturing Practices Workshop', total: 6, present: 6, absent: 0, percentage: 100.0, safeBunks: 2, needToAttend: 0),
    ],
    todaySchedule: [
      PeriodSlot(subject: 'Human Values and Ethics', timeSlot: '08:00-09:00', status: 'Present'),
      PeriodSlot(subject: 'Basic Electrical & Electronics Engg', timeSlot: '09:00-10:00', status: 'Present'),
      PeriodSlot(subject: 'Engineering Mathematics-I', timeSlot: '10:00-11:00', status: 'Present'),
      PeriodSlot(subject: 'Human Values and Ethics', timeSlot: '11:00-12:00', status: 'Present'),
      PeriodSlot(subject: 'Web Programming Lab', timeSlot: '12:50-13:50', status: 'Present'),
      PeriodSlot(subject: 'Web Programming Lab', timeSlot: '13:50-14:50', status: 'Present'),
    ],
  );

  Map<String, int> simulatedBunks = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F17),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  report.appName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: const Text('Live', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Text(
              '${report.studentName} • ${report.program}',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Metrics Row
          Row(
            children: [
              // Percentage Ring Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D121D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ATTENDANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[400])),
                      const SizedBox(height: 6),
                      Text(
                        '${report.overallPercentage}%',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: report.overallPercentage / 100,
                          backgroundColor: Colors.grey[900],
                          color: const Color(0xFF10B981),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${report.overallPresent}/${report.overallTotal} Lectures', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bunk Wallet Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D121D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BUNK WALLET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                      const SizedBox(height: 6),
                      Text(
                        '+${report.totalSafeBunks}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 6),
                      const Text('Safe cuts available without dropping below 75%', style: TextStyle(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Today's Timeline Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D121D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2638)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text("Today's Schedule (24-Sep)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('${report.todaySchedule.length} Periods', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFF1E2638)),
                ...report.todaySchedule.map((slot) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141A26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(slot.timeSlot, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white70)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(slot.subject, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('✓ Present', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // What-If Bunk Simulator & Subjects Header
          const Text('What-If Bunk Simulator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Subject Simulator Cards
          ...report.subjects.map((sub) {
            int extra = simulatedBunks[sub.code] ?? 0;
            int simTotal = sub.total + extra;
            double simPct = simTotal > 0 ? (sub.present / simTotal) * 100 : 0.0;
            bool isSafe = simPct >= 75.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D121D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E2638)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sub.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(sub.code, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSafe ? const Color(0xFF10B981).withOpacity(0.15) : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${simPct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSafe ? const Color(0xFF10B981) : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Skip: +$extra', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: extra.toDouble(),
                            min: 0,
                            max: 6,
                            divisions: 6,
                            activeColor: const Color(0xFF10B981),
                            inactiveColor: const Color(0xFF1E2638),
                            onChanged: (val) {
                              setState(() {
                                simulatedBunks[sub.code] = val.toInt();
                              });
                            },
                          ),
                        ),
                      ),
                      Text('Safe: +${sub.safeBunks}', style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Refined Signature Footer
          Center(
            child: Text(
              'Poornima Bunk Calculator • ${report.developer}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
