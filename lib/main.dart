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
    systemNavigationBarColor: Color(0xFF07090E),
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
        scaffoldBackgroundColor: const Color(0xFF07090E),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          surface: Color(0xFF0E131F),
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
  int _currentTabIndex = 0;
  AttendanceReport? _report;
  bool _isLoading = true;
  bool _isSyncing = false;
  final Map<String, int> _simulatedBunks = {};

  final _fallbackReport = AttendanceReport(
    appName: 'Poornima Bunk Calculator',
    developer: 'Crafted with precision by Gourav Singh (cyber)',
    studentName: 'Gaurav',
    program: 'B.Tech CY • PCE (Sem 1)',
    overallTotal: 72, overallPresent: 69, overallAbsent: 3,
    overallPercentage: 95.8, totalSafeBunks: 20,
    bunkAdvice: 'You can safely miss up to 20 class(es) and remain comfortably above 75%.',
    isTcsDown: false, lastSyncedAt: '24-Sep-2026 23:30', date: 'Today, 24 Sep',
    subjects: [
      Subject(code: 'PC261FY405', name: 'Human Values and Ethics', total: 10, present: 10, absent: 0, percentage: 100.0, safeBunks: 3, needToAttend: 0),
      Subject(code: 'PC261CY104', name: 'Basic Electrical & Electronics', total: 9, present: 7, absent: 2, percentage: 77.8, safeBunks: 0, needToAttend: 0),
      Subject(code: 'PC261FY103', name: 'Engineering Mathematics-I', total: 12, present: 12, absent: 0, percentage: 100.0, safeBunks: 4, needToAttend: 0),
      Subject(code: 'PC261CY124', name: 'Web Programming Lab', total: 6, present: 6, absent: 0, percentage: 100.0, safeBunks: 2, needToAttend: 0),
      Subject(code: 'PC261FY102', name: 'Engineering Physics', total: 6, present: 5, absent: 1, percentage: 83.3, safeBunks: 0, needToAttend: 0),
      Subject(code: 'PC261FY106', name: 'Programming with C', total: 3, present: 3, absent: 0, percentage: 100.0, safeBunks: 1, needToAttend: 0),
      Subject(code: 'NSP001', name: 'Non Syllabus Project', total: 6, present: 6, absent: 0, percentage: 100.0, safeBunks: 2, needToAttend: 0),
      Subject(code: 'PC261FY122', name: 'Engineering Physics Lab', total: 4, present: 4, absent: 0, percentage: 100.0, safeBunks: 1, needToAttend: 0),
      Subject(code: 'PC261FY123', name: 'Programming with C Lab', total: 2, present: 2, absent: 0, percentage: 100.0, safeBunks: 0, needToAttend: 0),
      Subject(code: 'PC261FY526', name: 'Language Lab*', total: 6, present: 6, absent: 0, percentage: 100.0, safeBunks: 2, needToAttend: 0),
      Subject(code: 'PC261FY628', name: 'IDEA Lab Workshop', total: 2, present: 2, absent: 0, percentage: 100.0, safeBunks: 0, needToAttend: 0),
      Subject(code: 'PC261FY629', name: 'Manufacturing Practices Workshop', total: 6, present: 6, absent: 0, percentage: 100.0, safeBunks: 2, needToAttend: 0),
    ],
    todaySchedule: [
      PeriodSlot(subject: 'Human Values and Ethics', timeSlot: '08:00 AM', status: 'Present'),
      PeriodSlot(subject: 'Basic Electrical Engineering', timeSlot: '09:00 AM', status: 'Present'),
      PeriodSlot(subject: 'Engineering Mathematics-I', timeSlot: '10:00 AM', status: 'In Progress'),
      PeriodSlot(subject: 'Human Values and Ethics', timeSlot: '11:00 AM', status: 'Pending'),
      PeriodSlot(subject: 'Web Programming Lab', timeSlot: '12:50 PM', status: 'Pending'),
      PeriodSlot(subject: 'Web Programming Lab', timeSlot: '01:50 PM', status: 'Pending'),
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
      if (scraped != null && scraped.overallTotal > 0) {
        _report = scraped;
      } else {
        _report = _fallbackReport;
      }
      _isLoading = false;
    });
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    HapticFeedback.mediumImpact();
    final scraped = await ScraperService.fetchAttendance();
    setState(() {
      if (scraped != null && scraped.overallTotal > 0) {
        _report = scraped;
      }
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

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildCustomHeader(r),

            // Main Body Content
            Expanded(
              child: _currentTabIndex == 0
                  ? _buildOverviewTab(r)
                  : _buildTimelineTab(r),
            ),

            // Bottom Navigation Bar
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // --- Top Custom Header ---
  Widget _buildCustomHeader(AttendanceReport r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'GS',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.program,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Live status pill
          GestureDetector(
            onTap: _syncNow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _isSyncing
                      ? const SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFF10B981),
                          ),
                        )
                      : Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF10B981),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                  const SizedBox(width: 7),
                  const Text(
                    'TCS iON: Live',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF34D399),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 1: Overview Tab (With Fixed Layout & Live Dynamic Math) ---
  Widget _buildOverviewTab(AttendanceReport r) {
    // Dynamic recalculation driven by the sliders
    int extraBunksSum = 0;
    for (final v in _simulatedBunks.values) {
      extraBunksSum += v;
    }

    final simTotalLectures = r.overallTotal + extraBunksSum;
    final simPresentLectures = r.overallPresent;
    final liveMasterPct = simTotalLectures > 0
        ? double.parse(((simPresentLectures / simTotalLectures) * 100).toStringAsFixed(1))
        : 0.0;
    final liveSafeBunksRemaining = max(0, r.totalSafeBunks - extraBunksSum);
    final isMasterSafe = liveMasterPct >= 75.0;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        const SizedBox(height: 10),

        // Hero Card: Dedicated Non-Clipping Layout
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0C101A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isMasterSafe ? const Color(0xFF1A2234) : const Color(0xFFEF4444).withOpacity(0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Clean Centered Radial Progress Ring (No crop, full stroke clearance)
              SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(210, 210),
                      painter: _RadialGaugePainter(percentage: liveMasterPct),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${liveMasterPct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: isMasterSafe ? Colors.white : const Color(0xFFEF4444),
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$simPresentLectures / $simTotalLectures Lectures',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Embedded Dual Stat Bar: Lectures + Live Dynamic Bunk Wallet
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF26334D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[400])),
                          const SizedBox(height: 4),
                          Text(
                            isMasterSafe ? 'SAFE' : 'CRITICAL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isMasterSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('Above 75% goal', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A2B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF26334D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BUNK WALLET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[400])),
                          const SizedBox(height: 4),
                          Text(
                            '+$liveSafeBunksRemaining Safe',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            extraBunksSum > 0 ? '$extraBunksSum simulated skip' : 'Available to bunk',
                            style: TextStyle(fontSize: 10, color: extraBunksSum > 0 ? const Color(0xFFFBBF24) : Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Next Class Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0C101A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF1A2234), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Class',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '14m left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF87171),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Engineering Mathematics-I',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Room #3043 • Theory',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '10:00 AM',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // What-If Bunk Simulator Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What-If Bunk Simulator',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Slide to test missing classes live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            if (extraBunksSum > 0)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _simulatedBunks.clear());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Subject Simulator Cards
        ...r.subjects.map((sub) {
          final extra = _simulatedBunks[sub.code] ?? 0;
          final simTotal = sub.total + extra;
          final simPct = simTotal > 0 ? (sub.present / simTotal) * 100 : 0.0;
          final safe = simPct >= 75.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0C101A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1A2234)),
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
                          Text(
                            sub.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub.code,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: safe
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${simPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: safe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '+$extra skip',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          value: extra.toDouble(),
                          min: 0,
                          max: 6,
                          divisions: 6,
                          activeColor: const Color(0xFF10B981),
                          inactiveColor: const Color(0xFF1E2638),
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _simulatedBunks[sub.code] = v.toInt());
                          },
                        ),
                      ),
                    ),
                    Text(
                      '+${sub.safeBunks} safe',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),
        Center(
          child: Text(
            'Poornima Bunk Calculator • ${r.developer}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- Tab 2: Timeline Schedule Tab ---
  Widget _buildTimelineTab(AttendanceReport r) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Today, 24 Sep',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF271B11),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF78350F), width: 1),
              ),
              child: const Text(
                'Showing offline data',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFBBF24),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Vertical Connected Timeline List
        ...List.generate(r.todaySchedule.length, (index) {
          final slot = r.todaySchedule[index];
          final isLast = index == r.todaySchedule.length - 1;
          final isInProgress = slot.status == 'In Progress';
          final isPresent = slot.status == 'Present';

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isInProgress
                            ? const Color(0xFF0A192F)
                            : const Color(0xFF0F172A),
                        border: Border.all(
                          color: isInProgress
                              ? const Color(0xFF38BDF8)
                              : (isPresent ? const Color(0xFF10B981) : const Color(0xFF334155)),
                          width: isInProgress ? 4 : 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C101A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isInProgress
                            ? const Color(0xFF0284C7)
                            : const Color(0xFF1A2234),
                        width: isInProgress ? 1.8 : 1,
                      ),
                      boxShadow: isInProgress
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withOpacity(0.2),
                                blurRadius: 16,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.timeSlot,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slot.subject,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isPresent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                                    SizedBox(width: 5),
                                    Text(
                                      'Present',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isInProgress)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'In Progress',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),

                            if (!isPresent && !isInProgress)
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Next sync: 1:55 PM',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF090D15),
        border: Border(top: BorderSide(color: Color(0xFF1A2234), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.grid_view_rounded, 'Dashboard'),
          _navItem(1, Icons.calendar_today_rounded, 'Schedule'),
          _navItem(2, Icons.analytics_outlined, 'Analytics'),
          _navItem(3, Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (index <= 1) {
          setState(() => _currentTabIndex = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for the Smooth Circular Radial Gauge with Padding Protection
class _RadialGaugePainter extends CustomPainter {
  final double percentage;
  _RadialGaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // 16px safety inset to prevent stroke clipping
    final radius = (size.width - 32) / 2;

    // Background track ring
    final bgPaint = Paint()
      ..color = const Color(0xFF141C2E)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final isSafe = percentage >= 75.0;

    // Active progress arc with smooth gradient
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: isSafe
            ? [const Color(0xFF059669), const Color(0xFF10B981), const Color(0xFF34D399), const Color(0xFF06B6D4)]
            : [const Color(0xFFDC2626), const Color(0xFFEF4444), const Color(0xFFF87171), const Color(0xFFFBBF24)],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2;
    final sweepAngle = ((percentage.clamp(0.0, 100.0)) / 100) * 2 * pi * 0.95;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
