import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../database/db_helper.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final DBHelper _dbHelper = DBHelper();
  List<TransactionItem> _list = [];
  double _totalInvest = 0.0;
  double _totalMonthlyProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final data = await _dbHelper.getAll();
    double invest = 0.0;
    double monthlyP = 0.0;

    for (var item in data) {
      invest += item.amount;
      monthlyP += item.monthlyProfit;
    }

    if (!mounted) return;
    setState(() {
      _list = data;
      _totalInvest = invest;
      _totalMonthlyProfit = monthlyP;
    });
  }

  // ১ মাস পূর্ণ হয়েছে কিনা যাচাই (৩০ দিন বা বেশি)
  bool _isOneMonthDue(String startDate, String lastPaymentDate) {
    try {
      final baseDateStr = lastPaymentDate.isNotEmpty ? lastPaymentDate : startDate;
      final baseDate = DateTime.parse(baseDateStr);
      final difference = DateTime.now().difference(baseDate).inDays;
      return difference >= 30;
    } catch (_) {
      return false;
    }
  }

  // অটোমেটিক এসএমএস তৈরি ও অ্যাপ ওপেন
  void _sendAutoReminderSMS(TransactionItem item) async {
    if (item.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("গ্রাহকের কোনো ফোন নম্বর যোগ করা নেই!")),
      );
      return;
    }

    final message = "সম্মানিত গ্রাহক ${item.title}, আপনার ProfitTrack একাউন্টের ১ মাসের মাসিক মুনাফা ৳${item.monthlyProfit.toStringAsFixed(0)} প্রদানের সময় হয়েছে। অনুগ্রহ করে অতিসত্বর পরিশোধ করুন। ধন্যবাদ।";
    final uri = Uri.parse("sms:${item.phone}?body=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("মেসেজ অ্যাপ চালু করা যায়নি")),
      );
    }
  }

  // কিস্তির টাকা সংগ্রহের ডায়ালগ
  void _showAddPaymentDialog(TransactionItem item) {
    int selectedMonths = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalPaying = item.monthlyProfit * selectedMonths;
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text("${item.title} - মুনাফা আদায়"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("মাসিক নির্ধারিত লাভ: ৳${item.monthlyProfit.toStringAsFixed(0)}"),
                const SizedBox(height: 15),
                const Text("কয় মাসের টাকা দিতে চায়:"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                      onPressed: selectedMonths > 1
                          ? () => setModalState(() => selectedMonths--)
                          : null,
                    ),
                    Text(
                      "$selectedMonths মাস",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                      onPressed: () => setModalState(() => selectedMonths++),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "মোট আদায়: ৳${totalPaying.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                onPressed: () async {
                  await _dbHelper.addProfitPayment(item.id!, item.paidMonths, selectedMonths, totalPaying);
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$selectedMonths মাসের টাকা জমা হয়েছে")),
                  );
                },
                child: const Text("জমা নিশ্চিত করুন"),
              ),
            ],
          );
        },
      ),
    );
  }

  // পেমেন্ট লগ হিস্ট্রি ডায়ালগ
  void _showHistoryDialog(TransactionItem item) async {
    final logs = await _dbHelper.getLogs(item.id!);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("টাকা প্রদানের খতিয়ান: ${item.title}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 12),
            logs.isEmpty
                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("এখন পর্যন্ত কোনো মাসের মুনাফা জমা দেওয়া হয়নি।")))
                : Expanded(
                    child: ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (c, i) {
                        final log = logs[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.cyanAccent),
                            title: Text("পরিশোধ: ${log.monthCount} মাসের মুনাফা"),
                            subtitle: Text("তারিখ: ${log.paymentDate}"),
                            trailing: Text("৳${log.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ),
                        );
                      },
                    ),
                  )
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final rateController = TextEditingController(text: "10.0");
    final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("নতুন খতিয়ান যুক্ত করুন", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 15),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "গ্রাহকের নাম *", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "মোবাইল নম্বর (SMS পাঠানোর জন্য) *", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "মূলধন / বিনিয়োগ (৳) *", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: rateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "মাসিক লাভের হার (%) *", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: "বিনিয়োগ শুরুর তারিখ (YYYY-MM-DD)", border: OutlineInputBorder())),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    final title = titleController.text.trim();
                    final phone = phoneController.text.trim();
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    final rate = double.tryParse(rateController.text) ?? 0.0;
                    final monthlyProfit = (amount * rate) / 100;

                    if (title.isNotEmpty && amount > 0) {
                      await _dbHelper.insert(
                        TransactionItem(
                          title: title,
                          phone: phone,
                          amount: amount,
                          profitRate: rate,
                          monthlyProfit: monthlyProfit,
                          startDate: dateController.text,
                          paidMonths: 0,
                        ),
                      );
                      nav.pop();
                      _loadData();
                    }
                  },
                  child: const Text("সংরক্ষণ করুন", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentIndex == 0 ? "ProfitTrack BD (মাসিক লেজার)" : "সেটিংস")),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              onPressed: _showAddDialog,
              icon: const Icon(Icons.person_add),
              label: const Text("নতুন হিসাব"),
            )
          : null,
      body: _currentIndex == 0
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // মূল ব্যালেন্স কার্ড
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("মোট বিনিয়োগকৃত মূলধন", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text("৳ ${_totalInvest.toStringAsFixed(2)}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Divider(color: Colors.white24, height: 25),
                      Text("মাসিক মোট প্রত্যাশিত মুনাফা: +৳ ${_totalMonthlyProfit.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("গ্রাহকদের তালিকা ও মুনাফা বিবরণী", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ..._list.map((item) {
                  final isDue = _isOneMonthDue(item.startDate, item.lastPaymentDate);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              Text("৳ ${item.amount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("শুরু: ${item.startDate} | মাসিক মুনাফা: ৳${item.monthlyProfit.toStringAsFixed(0)} (${item.profitRate}%)", style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text("পরিশোধ করেছে: ${item.paidMonths} মাসের লাভ", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                          if (item.lastPaymentDate.isNotEmpty) Text("সর্বশেষ পরিশোধের তারিখ: ${item.lastPaymentDate}", style: const TextStyle(fontSize: 12, color: Colors.white60)),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isDue)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.send_to_mobile, size: 16),
                                  label: const Text("অটো SMS পাঠান"),
                                  onPressed: () => _sendAutoReminderSMS(item),
                                )
                              else
                                const Text("✅ মেয়াদ রানিং", style: TextStyle(color: Colors.greenAccent, fontSize: 13)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.history, color: Colors.blueAccent),
                                    tooltip: "খতিয়ান দেখুন",
                                    onPressed: () => _showHistoryDialog(item),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                                    onPressed: () => _showAddPaymentDialog(item),
                                    child: const Text("টাকা জমা"),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () async {
                                      await _dbHelper.delete(item.id!);
                                      _loadData();
                                    },
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }),
              ],
            )
          : SettingsScreen(onDataChanged: _loadData),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppTheme.surface,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: "খতিয়ান"),
          NavigationDestination(icon: Icon(Icons.settings), label: "সেটিংস"),
        ],
      ),
    );
  }
}
