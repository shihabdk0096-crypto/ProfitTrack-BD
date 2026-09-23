import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../database/db_helper.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  const SettingsScreen({super.key, required this.onDataChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DBHelper _db = DBHelper();

  void _clearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("ডাটাবেজ রিসেট", style: TextStyle(color: Colors.redAccent)),
        content: const Text("আপনি কি সমস্ত লেনদেন মুছে ফেলতে চান? এটি আর ফিরিয়ে আনা যাবে না।"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              await _db.clearAll();
              widget.onDataChanged();
              navigator.pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text("সব লেনদেন মুছে ফেলা হয়েছে")),
              );
            },
            child: const Text("মুছুন", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("সেটিংস ও নিরাপত্তা")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("অ্যাপ কনফিগারেশন", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.percent, color: AppTheme.primary),
              title: Text("ডিফল্ট লাভ মার্জিন"),
              subtitle: Text("বর্তমান আদর্শ হার: ১০.০%"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.currency_exchange, color: Colors.blueAccent),
              title: Text("মুদ্রা প্রতীক"),
              subtitle: Text("বাংলাদেশী টাকা (৳ BDT)"),
              trailing: Icon(Icons.check, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 20),
          const Text("নিরাপত্তা ও প্রাইভেসি", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: Colors.tealAccent),
              title: const Text("বায়োমেট্রিক ও পিন সুরক্ষা"),
              subtitle: const Text("অ্যাপ চালু করার সময় ভেরিফিকেশন চাইবে"),
              value: true,
              activeTrackColor: AppTheme.primary.withAlpha(120),
              activeThumbImage: null,
              onChanged: (val) {},
            ),
          ),
          const SizedBox(height: 20),
          const Text("ডাটা ম্যানেজমেন্ট", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text("সকল হিসাব মুছে ফেলুন", style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text("ক্লিয়ার ডাটাবেজ অ্যান্ড ক্যাশ"),
              onTap: _clearData,
            ),
          ),
        ],
      ),
    );
  }
}
