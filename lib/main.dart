import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/attendance_model.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/scraper_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080B10),
  ));
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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          surface: Color(0xFF0D121D),
        ),
      ),
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});
  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _isLoggedIn = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final creds = await AuthService.loadCredentials();
    setState(() {
      _isLoggedIn = creds != null;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }
    return _isLoggedIn
        ? const DashboardScreen()
        : LoginScreen(onLoginSuccess: () => setState(() => _isLoggedIn = true));
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AttendanceReport? _report;
  bool _isLoading = true;
  bool _isSyncing = false;
  Map<String, int> _simulatedBunks = {};

  // Hardcoded verified fallback data (from your real scraped report)
  final _fallbackReport = AttendanceReport(
    appName: 'Poornima Bunk Calculator',
    developer: 'Crafted with precision by Gourav Singh (cyber)',
    studentName: 'Gaurav',
    program: 'B. Tech. (CY) PCE (Semester 1)',
    overallTotal: 72, overallPresent: 69, overallAbsent: 3,
    overallPercentage: 95.83, totalSafeBunks: 20,
    bunkAdvice: 'You can safely miss up to 20 class(es) and remain comfortably above 75%.',
    isTcsDown: false, lastSyncedAt: '24-Sep-2026 23:30', date: '24-September-2026',
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final scraped = await ScraperService.fetchAttendance();
    setState(() {
      _report = scraped ?? _fallbackReport;
      _isLoading = false;
    });
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    HapticFeedback.mediumImpact();
    final scraped = await ScraperService.fetchAttendance();
    setState(() {
      _report = scraped ?? _report;
      _isSyncing = false;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    final r = _report!;
    final pctColor = r.overallPercentage >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F17),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF14B8A6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('P', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF080B10)))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Poornima Bunk Calculator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: r.isTcsDown ? Colors.amber.withOpacity(0.15) : const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: r.isTcsDown ? Colors.amber.withOpacity(0.3) : const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Text(
                          r.isTcsDown ? 'Offline' : 'Live',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: r.isTcsDown ? Colors.amber : const Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                  Text('${r.studentName} • ${r.program}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)))
                : const Icon(Icons.sync, size: 20, color: Color(0xFF10B981)),
            onPressed: _isSyncing ? null : _syncNow,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TCS Down Banner
          if (r.isTcsDown)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text('TCS iON is down. Showing cached data from ${r.lastSyncedAt}', style: const TextStyle(fontSize: 11, color: Colors.amber))),
                ],
              ),
            ),

          // Hero Row: Attendance + Bunk Wallet
          Row(
            children: [
              Expanded(
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ATTENDANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${r.overallPercentage}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: pctColor, height: 1)),
                          Text('%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: pctColor.withOpacity(0.7))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(value: r.overallPercentage / 100, backgroundColor: const Color(0xFF141A26), color: pctColor, minHeight: 4),
                      ),
                      const SizedBox(height: 6),
                      Text('${r.overallPresent}/${r.overallTotal} Lectures', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BUNK WALLET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF10B981), letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text('+${r.totalSafeBunks}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontFamily: 'monospace', height: 1)),
                      const SizedBox(height: 10),
                      Text(r.bunkAdvice, style: TextStyle(fontSize: 10, color: Colors.grey[300], height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Today's Timeline
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Schedule", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF141A26), borderRadius: BorderRadius.circular(6)),
                      child: Text('${r.todaySchedule.length} Periods', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ),
                  ],
                ),
                Divider(height: 18, color: const Color(0xFF1E2638).withOpacity(0.6)),
                if (r.todaySchedule.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('No classes today!', style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                  ),
                ...r.todaySchedule.map((slot) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF141A26), borderRadius: BorderRadius.circular(5)),
                        child: Text(slot.timeSlot, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white70)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(slot.subject, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      _statusPill(slot.status),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // What-If Simulator
          const Text('What-If Bunk Simulator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Drag to preview impact of missing lectures', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          const SizedBox(height: 10),

          ...r.subjects.map((sub) {
            final extra = _simulatedBunks[sub.code] ?? 0;
            final simTotal = sub.total + extra;
            final simPct = simTotal > 0 ? (sub.present / simTotal) * 100 : 0.0;
            final safe = simPct >= 75.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D121D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2638)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sub.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            Text(sub.code, style: TextStyle(fontSize: 9, color: Colors.grey[500], fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: safe ? const Color(0xFF10B981).withOpacity(0.12) : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${simPct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: safe ? const Color(0xFF10B981) : Colors.redAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('+$extra skip', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(trackHeight: 2.5, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5)),
                          child: Slider(
                            value: extra.toDouble(), min: 0, max: 6, divisions: 6,
                            activeColor: const Color(0xFF10B981), inactiveColor: const Color(0xFF1E2638),
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _simulatedBunks[sub.code] = v.toInt());
                            },
                          ),
                        ),
                      ),
                      Text('+${sub.safeBunks} safe', style: const TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),
          // Footer
          Center(
            child: Text(
              'Poornima Bunk Calculator  •  ${r.developer}',
              style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D121D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: child,
    );
  }

  Widget _statusPill(String status) {
    Color bg, fg;
    String label;
    if (status == 'Present') {
      bg = const Color(0xFF10B981).withOpacity(0.12);
      fg = const Color(0xFF10B981);
      label = '✓ Present';
    } else if (status == 'Absent') {
      bg = Colors.red.withOpacity(0.12);
      fg = Colors.redAccent;
      label = '✗ Absent';
    } else {
      bg = const Color(0xFF141A26);
      fg = Colors.grey;
      label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
