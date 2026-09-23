import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../database/db_helper.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController(text: 'admin');
  final TextEditingController _passController = TextEditingController();
  bool _obscureText = true;
  String _errorMsg = '';

  void _login() async {
    final user = _userController.text.trim();
    final pass = _passController.text.trim();
    final success = await DBHelper().verifyLogin(user, pass);

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _errorMsg = "ভুল ইউজারনেম অথবা পাসওয়ার্ড!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withAlpha(30),
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                child: const Icon(Icons.shield_outlined, size: 60, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              const Text("ProfitTrack BD", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text("নিরাপদ মাইক্রো-ফাইন্যান্স ও খতিয়ান", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 35),
              Card(
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _userController,
                        decoration: const InputDecoration(
                          labelText: "ইউজারনেম",
                          prefixIcon: Icon(Icons.person, color: AppTheme.primary),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: "পাসওয়ার্ড",
                          prefixIcon: const Icon(Icons.lock, color: AppTheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (_errorMsg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(_errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _login,
                          child: const Text("প্রবেশ করুন (Login)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("ডিফল্ট পাসওয়ার্ড: 1234", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
