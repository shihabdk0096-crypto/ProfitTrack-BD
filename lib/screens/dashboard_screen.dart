import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/transaction_model.dart';
import '../database/db_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<TransactionModel> _list = [];
  double _totalInvest = 0.0;
  double _totalProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final data = await _dbHelper.getTransactions();
    double invest = 0.0;
    double profit = 0.0;
    for (var item in data) {
      invest += item.amount;
      profit += item.netProfit;
    }
    if (!mounted) return;
    setState(() {
      _list = data;
      _totalInvest = invest;
      _totalProfit = profit;
    });
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final rateController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "নতুন বিনিয়োগ যুক্ত করুন",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "বিবরণ / গ্রাহক নাম", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "বিনিয়োগ মূলধন (৳)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "লাভের হার (%)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final nav = Navigator.of(ctx);
                  final title = titleController.text;
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  final rate = double.tryParse(rateController.text) ?? 0.0;
                  final profit = (amount * rate) / 100;

                  if (title.isNotEmpty && amount > 0) {
                    await _dbHelper.insertTransaction(
                      TransactionModel(
                        title: title,
                        amount: amount,
                        profitRate: rate,
                        netProfit: profit,
                        date: DateTime.now().toString().substring(0, 10),
                      ),
                    );
                    nav.pop();
                    _loadData();
                  }
                },
                child: const Text("নিশ্চিত করুন", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ProfitTrack BD", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("মোট মূলধন", style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text("৳ ${_totalInvest.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Divider(height: 30, color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("মোট আনুমানিক লাভ", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          Text("+৳ ${_totalProfit.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primary.withAlpha(50), borderRadius: BorderRadius.circular(20)),
                        child: const Text("Active Ledger", style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("সাম্প্রতিক হিসাব", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _list.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("কোনো লেনদেন যুক্ত করা হয়নি।", style: TextStyle(color: AppTheme.textSecondary))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _list.length,
                    itemBuilder: (ctx, index) {
                      final item = _list[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withAlpha(40),
                            child: const Icon(Icons.monetization_on_outlined, color: AppTheme.primary),
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("তারিখ: ${item.date} • হার: ${item.profitRate}%"),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("৳ ${item.amount}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("+৳ ${item.netProfit}", style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  )
          ],
        ),
      ),
    );
  }
}
