import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../database/db_helper.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  const SettingsScreen({super.key, required this.onDataChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DBHelper _db = DBHelper();

  void _exportToCloud() async {
    try {
      final jsonStr = await _db.exportBackupJSON();
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text("ব্যাকআপ ডাটা কপি হয়েছে"),
          content: const Text(
            "আপনার সমস্ত ডাটাবেজ ক্লিপবোর্ডে কপি করা হয়েছে। এখন আপনার জিমেইলে (বা গুগল ড্রাইভ নোটে) গিয়ে পেস্ট করে সুরক্ষিত রাখুন।",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ঠিক আছে"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ব্যাকআপ ত্রুটি: $e")),
      );
    }
  }

  void _importFromBackup() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("ব্যাকআপ ডাটা রিকভারি"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "জিমেইল বা ড্রাইভ থেকে সংরক্ষিত ব্যাকআপ কোডটি এখানে পেস্ট করুন:",
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '{"version": 1, ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("বাতিল"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                final ok = await _db.importBackupJSON(text);
                nav.pop();
                if (ok) {
                  widget.onDataChanged();
                  messenger.showSnackBar(
                    const SnackBar(content: Text("ডাটাবেজ সফলভাবে রিকভার হয়েছে!")),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("ভুল ব্যাকআপ ফরম্যাট!")),
                  );
                }
              }
            },
            child: const Text("রিকভার করুন"),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("নতুন পাসওয়ার্ড সেট করুন"),
        content: TextField(
          controller: passCtrl,
          decoration: const InputDecoration(
            labelText: "পাসওয়ার্ড",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("বাতিল"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (passCtrl.text.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await _db.updatePassword(passCtrl.text.trim());
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text("পাসওয়ার্ড সফলভাবে পরিবর্তিত হয়েছে")),
                );
              }
            },
            child: const Text("সংরক্ষণ করুন"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("সেটিংস ও ব্যাকআপ")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "ক্লাউড ব্যাকআপ ও জিমেইল রিকভারি",
            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.copy_all, color: Colors.cyanAccent),
              title: const Text("ব্যাকআপ ডাটা কপি করুন"),
              subtitle: const Text("কপি করে জিমেইল বা গুগল ড্রাইভে সেভ রাখুন"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _exportToCloud,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_download_outlined, color: Colors.greenAccent),
              title: const Text("ব্যাকআপ পেস্ট করে রিকভার করুন"),
              subtitle: const Text("সংরক্ষিত কোড বসিয়ে সব তথ্য ফিরিয়ে আনুন"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _importFromBackup,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "নিরাপত্তা সেটিংস",
            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.password, color: Colors.amberAccent),
              title: const Text("অ্যাপ পাসওয়ার্ড পরিবর্তন করুন"),
              subtitle: const Text("নিরাপত্তার জন্য পাসওয়ার্ড আপডেট রাখুন"),
              onTap: _changePassword,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.orangeAccent),
              title: const Text("লগআউট করুন"),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (c) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
