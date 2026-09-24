import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final creds = await AuthService.loadCredentials();
    if (creds != null) {
      _userController.text = creds['userId']!;
      _passController.text = creds['password']!;
    }
  }

  Future<void> _doLogin() async {
    setState(() { _isLoading = true; _error = null; });

    final userId = _userController.text.trim();
    final password = _passController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      setState(() { _isLoading = false; _error = 'Please enter your credentials'; });
      return;
    }

    final success = await AuthService.login(userId, password);

    if (success) {
      widget.onLoginSuccess();
    } else {
      setState(() { _isLoading = false; _error = 'Login failed. Check your credentials or network.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF10B981).withOpacity(0.25), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: const Center(
                    child: Text('P', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF080B10))),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Poornima Bunk Calculator',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in with your TCS iON credentials',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
                const SizedBox(height: 36),

                // User ID Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D121D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: TextField(
                    controller: _userController,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'TCS iON User ID (email)',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey[500], size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 12),

                // Password Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D121D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: TextField(
                    controller: _passController,
                    obscureText: _obscurePass,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Error Message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                  ),

                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _doLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: const Color(0xFF080B10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080B10)))
                        : const Text('Sign In & Sync Attendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 40),

                // Signature
                Text(
                  'Crafted with precision by Gourav Singh (cyber)',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }
}
