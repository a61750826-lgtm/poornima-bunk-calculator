import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/attendance_model.dart';
import 'services/scraper_service.dart';
import 'services/dynamic_timetable_service.dart';
import 'screens/tcs_webview_sync_screen.dart';

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
  int _currentTabIndex = 0;
  AttendanceReport? _report;
  bool _isLoading = true;
  bool _isLiveSync = false;
  bool _hasSyncFailed = false;
  String? _syncError;
  final Map<String, int> _simulatedBunks = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final report = await ScraperService.loadData();
    setState(() {
      _report = report;
      _isLoading = false;
    });
  }

  void _openSyncWebView() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TcsWebviewSyncScreen(
          onSyncSuccess: (newReport) {
            setState(() {
              _report = newReport;
              _isLiveSync = true;
              _hasSyncFailed = false;
              _syncError = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attendance synchronized with TCS iON!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
          onSyncFailure: (errorReason) {
            setState(() {
              _hasSyncFailed = true;
              _syncError = errorReason;
              _isLiveSync = false;
            });
          },
        ),
      ),
    );
  }

  Future<void> _markClassAttendance(String subjectName, bool attended) async {
    if (_report == null) return;
    HapticFeedback.mediumImpact();
    final updated = await ScraperService.recordClass(
      current: _report!,
      subjectName: subjectName,
      wasAttended: attended,
    );
    setState(() => _report = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(attended ? 'Marked Attended: $subjectName (+1)' : 'Marked Bunked: $subjectName'),
        backgroundColor: attended ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        duration: const Duration(seconds: 2),
      ),
    );
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
            _buildCustomHeader(r),
            Expanded(
              child: IndexedStack(
                index: _currentTabIndex,
                children: [
                  _buildOverviewTab(r),
                  _buildTimelineTab(r),
                  _buildAnalyticsTab(r),
                  _buildProfileTab(r),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // --- Top Header ---
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
          // Dynamic status pill
          GestureDetector(
            onTap: _openSyncWebView,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _hasSyncFailed
                    ? const Color(0xFF2A1215).withOpacity(0.8)
                    : (_isLiveSync
                        ? const Color(0xFF064E3B).withOpacity(0.4)
                        : const Color(0xFF271B11).withOpacity(0.6)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasSyncFailed
                      ? const Color(0xFFEF4444).withOpacity(0.5)
                      : (_isLiveSync
                          ? const Color(0xFF10B981).withOpacity(0.35)
                          : const Color(0xFFF59E0B).withOpacity(0.35)),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _hasSyncFailed
                          ? const Color(0xFFEF4444)
                          : (_isLiveSync ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _hasSyncFailed
                        ? 'Sync Failed'
                        : (_isLiveSync ? 'TCS iON: Synced' : 'Offline Mode'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _hasSyncFailed
                          ? const Color(0xFFF87171)
                          : (_isLiveSync ? const Color(0xFF34D399) : const Color(0xFFFBBF24)),
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

  // --- Tab 0: Overview Dashboard ---
  Widget _buildOverviewTab(AttendanceReport r) {
    int extraBunksSum = 0;
    _simulatedBunks.forEach((_, count) => extraBunksSum += count);

    final displayTotal = r.overallTotal + extraBunksSum;
    final displayPresent = r.overallPresent;
    final displayPct = displayTotal > 0 ? (displayPresent / displayTotal) * 100 : 0.0;
    final displaySafeBunks = max(0, ((displayPresent - 0.75 * displayTotal) / 0.75).floor());
    final isSafe = displayPct >= 75.0;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Sync Failure Alert Banner
        if (_hasSyncFailed && _syncError != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1014),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sync_problem_rounded, color: Color(0xFFF87171), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TCS iON Sync Failed',
                        style: TextStyle(
                          color: Color(0xFFF87171),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _syncError!,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _openSyncWebView,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E171B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFFCA5A5)),
                              SizedBox(width: 6),
                              Text(
                                'Retry Connection',
                                style: TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  onPressed: () => setState(() => _hasSyncFailed = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Main Radial Gauge Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0C101A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF1A2234), width: 1.2),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _RadialGaugePainter(percentage: displayPct),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${displayPct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                            shadows: [
                              Shadow(
                                color: (isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.4),
                                blurRadius: 18,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$displayPresent / $displayTotal Lectures',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text(
                            isSafe ? 'SAFE' : 'CRITICAL',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                          ),
                          const SizedBox(height: 2),
                          Text(isSafe ? 'Above 75% goal' : 'Below minimum', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BUNK WALLET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text(
                            isSafe ? '+$displaySafeBunks Safe' : '0 Safe',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isSafe ? const Color(0xFF38BDF8) : const Color(0xFFEF4444)),
                          ),
                          const SizedBox(height: 2),
                          Text(isSafe ? 'Available to bunk' : 'Attend next classes', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
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
        _buildDynamicNextClassCard(),
        const SizedBox(height: 20),

        // What-If Simulator Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What-If Bunk Simulator',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Slide to test missing classes live',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[400]),
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
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8))),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

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
                          Text(sub.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(sub.code, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: safe ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${simPct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: safe ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('+$extra skip', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
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
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- Dynamic Next Class Card ---
  Widget _buildDynamicNextClassCard() {
    final nextInfo = DynamicTimetableService.getNextClassOverview();
    final badgeColor = nextInfo.isCompleted ? const Color(0xFF10B981) : const Color(0xFF38BDF8);

    return Container(
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
                nextInfo.cardHeader,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  nextInfo.badgeText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextInfo.subjectName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextInfo.slotInfo,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Text(
                nextInfo.timeSlot,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Tab 1: Timeline Schedule Tab ---
  Widget _buildTimelineTab(AttendanceReport r) {
    final now = DateTime.now();
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dynamicDateStr = 'Today, ${now.day} ${months[now.month]}';
    final periods = DynamicTimetableService.getDynamicPeriodsForToday();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              dynamicDateStr,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Text(
                '${periods.length} Periods',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        ...List.generate(periods.length, (index) {
          final slot = periods[index];
          final isLast = index == periods.length - 1;
          final isInProgress = slot.status == 'In Progress';
          final isCompleted = slot.status == 'Completed';

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
                        color: isInProgress ? const Color(0xFF0A192F) : const Color(0xFF0F172A),
                        border: Border.all(
                          color: isInProgress
                              ? const Color(0xFF38BDF8)
                              : (isCompleted ? const Color(0xFF10B981) : const Color(0xFF334155)),
                          width: isInProgress ? 4 : 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(width: 2, color: const Color(0xFF1E293B)),
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
                        color: isInProgress ? const Color(0xFF0284C7) : const Color(0xFF1A2234),
                        width: isInProgress ? 1.8 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slot.timeSlot, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                        const SizedBox(height: 6),
                        Text(slot.subject, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isInProgress
                                    ? const Color(0xFF0284C7).withOpacity(0.2)
                                    : (isCompleted
                                        ? const Color(0xFF10B981).withOpacity(0.12)
                                        : const Color(0xFF1E293B)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                slot.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isInProgress
                                      ? const Color(0xFF38BDF8)
                                      : (isCompleted ? const Color(0xFF10B981) : Colors.grey[400]),
                                ),
                              ),
                            ),
                            // Quick Action Buttons
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _markClassAttendance(slot.subject, true),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF064E3B).withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                    ),
                                    child: const Text('+ Attended', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF34D399))),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _markClassAttendance(slot.subject, false),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7F1D1D).withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                                    ),
                                    child: const Text('- Bunked', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFF87171))),
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

  // --- Tab 2: Analytics Tab ---
  Widget _buildAnalyticsTab(AttendanceReport r) {
    final dangerSubjects = r.subjects.where((s) => s.percentage < 80.0).toList();
    final sortedByBuffer = List<Subject>.from(r.subjects)..sort((a, b) => b.safeBunks.compareTo(a.safeBunks));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const Text(
          'Attendance Analytics',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        Text('In-depth breakdown of your academic standing', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        const SizedBox(height: 20),

        if (dangerSubjects.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF271B11),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF78350F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 18),
                    SizedBox(width: 8),
                    Text('Danger Zone Alert (<80%)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFBBF24))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${dangerSubjects.first.name} is currently at ${dangerSubjects.first.percentage}%. Avoid missing this subject.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        const Text('Highest Bunk Buffer Ranking', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 12),

        ...sortedByBuffer.take(5).map((s) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0C101A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1A2234)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('${s.present}/${s.total} Lectures Attended (${s.percentage}%)', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('+${s.safeBunks} safe', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF38BDF8))),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // --- Tab 3: Profile & Settings Tab ---
  Widget _buildProfileTab(AttendanceReport r) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const Text(
          'Student Profile & Sync',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0C101A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1A2234)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E293B),
                      border: Border.all(color: const Color(0xFF334155), width: 1.5),
                    ),
                    child: const Center(
                      child: Text('GS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(r.program, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      const SizedBox(height: 2),
                      const Text('Poornima College of Engineering (9253)', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF1A2234)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Last Synced', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  Text(r.lastSyncedAt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Sync Trigger Button
        ElevatedButton.icon(
          onPressed: _openSyncWebView,
          icon: const Icon(Icons.sync_rounded, color: Colors.black),
          label: const Text('Sync with TCS iON Portal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 12),

        // Reset Baseline Button
        OutlinedButton.icon(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            final reset = await ScraperService.resetToBaseline();
            setState(() {
              _report = reset;
              _simulatedBunks.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reset to verified college baseline (72 lectures, 95.8%)')),
            );
          },
          icon: const Icon(Icons.restore_rounded, color: Colors.grey, size: 18),
          label: const Text('Reset Attendance Records', style: TextStyle(color: Colors.grey)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFF1A2234)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 28),
        Center(
          child: Text(
            r.developer,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
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
        setState(() => _currentTabIndex = index);
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
    final radius = (size.width - 32) / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFF141C2E)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final isSafe = percentage >= 75.0;

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
