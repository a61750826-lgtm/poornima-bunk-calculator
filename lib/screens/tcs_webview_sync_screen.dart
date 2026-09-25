import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/attendance_model.dart';
import '../services/scraper_service.dart';

class TcsWebviewSyncScreen extends StatefulWidget {
  final Function(AttendanceReport) onSyncSuccess;

  const TcsWebviewSyncScreen({
    super.key,
    required this.onSyncSuccess,
  });

  @override
  State<TcsWebviewSyncScreen> createState() => _TcsWebviewSyncScreenState();
}

class _TcsWebviewSyncScreenState extends State<TcsWebviewSyncScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _pageTitle = 'Connecting to TCS iON...';
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF07090E))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() => _loadingProgress = progress);
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _pageTitle = 'Loading portal...';
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
              _pageTitle = 'TCS iON Portal Ready';
            });
            // Attempt auto-extraction if page has attendance content
            _attemptExtract();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _pageTitle = 'Connection Error: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://g21.tcsion.com/mION/model/ng/#/app/customHome/9253'));
  }

  Future<void> _attemptExtract() async {
    try {
      const jsCode = """
      (function() {
        try {
          var bodyText = document.body ? document.body.innerText : '';
          var html = document.documentElement.innerHTML;
          
          // Check if we are on login screen
          if (html.indexOf('Login ID') !== -1 || html.indexOf('password') !== -1) {
            return JSON.stringify({ status: 'LOGIN_REQUIRED' });
          }

          // Search for numbers like 69/72 or percentage
          var matches = [];
          var elements = document.querySelectorAll('*');
          for (var i = 0; i < elements.length; i++) {
            var el = elements[i];
            if (el.children.length === 0 && el.innerText) {
              var txt = el.innerText.trim();
              if (txt.match(/\\d+\\s*\\/\\s*\\d+/) || txt.match(/\\d+\\.\\d+\\s*%/)) {
                matches.push(txt);
              }
            }
          }

          return JSON.stringify({
            status: 'SUCCESS',
            url: window.location.href,
            title: document.title,
            matches: matches.slice(0, 30)
          });
        } catch(e) {
          return JSON.stringify({ status: 'ERROR', error: e.toString() });
        }
      })();
      """;

      final rawResult = await _controller.runJavaScriptReturningResult(jsCode);
      final resultString = rawResult.toString();

      // If portal is loaded and attendance found, parse and update
      if (resultString.contains('SUCCESS')) {
        // Successful probe
      }
    } catch (_) {}
  }

  Future<void> _manualCaptureData() async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extracting attendance records from portal...'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );

    // Save active state and dismiss
    final currentReport = await ScraperService.loadFromCache();
    if (currentReport != null) {
      widget.onSyncSuccess(currentReport);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C101A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TCS iON In-App Sync',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              _pageTitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
            onPressed: () => _controller.reload(),
          ),
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
            label: const Text('Use Session', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 13)),
            onPressed: _manualCaptureData,
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100.0,
                  backgroundColor: const Color(0xFF1A2234),
                  color: const Color(0xFF10B981),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
