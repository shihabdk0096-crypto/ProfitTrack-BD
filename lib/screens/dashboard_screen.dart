import 'package:flutter/material.dart';
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
  List<TransactionItem> _allList = [];
  List<TransactionItem> _filteredList = [];

  double _totalInvest = 0.0;
  double _totalProfit = 0.0;
  double _paidAmount = 0.0;

  String _searchQuery = "";
  String _selectedFilter = "all";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final data = await _dbHelper.getAll();
    double invest = 0.0;
    double profit = 0.0;
    double paid = 0.0;

    for (var item in data) {
      invest += item.amount;
      profit += item.netProfit;
      if (item.status == 'paid') {
        paid += item.amount;
      }
    }

    if (!mounted) return;
    setState(() {
      _allList = data;
      _totalInvest = invest;
      _totalProfit = profit;
      _paidAmount = paid;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredList = _allList.where((item) {
        final matchesQuery = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.phone.contains(_searchQuery);
        final matchesStatus = _selectedFilter == "all" || item.status == _selectedFilter;
        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  void _showEntryDialog({TransactionItem? editItem}) {
    final titleController = TextEditingController(text: editItem?.title ?? '');
    final phoneController = TextEditingController(text: editItem?.phone ?? '');
    final amountController = TextEditingController(text: editItem != null ? editItem.amount.toString() : '');
    final rateController = TextEditingController(text: editItem != null ? editItem.profitRate.toString() : '10.0');
    final noteController = TextEditingController(text: editItem?.note ?? '');

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editItem == null ? "নতুন খতিয়ান এন্ট্রি" : "হিসাব পরিবর্তন করুন",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "গ্রাহকের নাম *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "মোবাইল নম্বর",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "মূলধন (৳) *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "লাভের হার (%) *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: "নোট / বিবরণ",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
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
                    final title = titleController.text.trim();
                    final phone = phoneController.text.trim();
                    final note = noteController.text.trim();
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    final rate = double.tryParse(rateController.text) ?? 0.0;
                    final profit = (amount * rate) / 100;

                    if (title.isNotEmpty && amount > 0) {
                      if (editItem == null) {
                        await _dbHelper.insert(
                          TransactionItem(
                            title: title,
                            phone: phone,
                            amount: amount,
                            profitRate: rate,
                            netProfit: profit,
                            date: DateTime.now().toString().substring(0, 10),
                            status: 'pending',
                            note: note,
                          ),
                        );
                      } else {
                        await _dbHelper.update(
                          TransactionItem(
                            id: editItem.id,
                            title: title,
                            phone: phone,
                            amount: amount,
                            profitRate: rate,
                            netProfit: profit,
                            date: editItem.date,
                            status: editItem.status,
                            note: note,
                          ),
                        );
                      }
                      nav.pop();
                      _loadData();
                    }
                  },
                  child: Text(
                    editItem == null ? "সংরক্ষণ করুন" : "আপডেট নিশ্চিত করুন",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(70), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("সর্বমোট বিনিয়োগ / মূলধন", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primary.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                      child: const Text("PRO FINANCIAL", style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text("৳ ${_totalInvest.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const Divider(height: 28, color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("মোট মুনাফা (লাভ)", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text("+৳ ${_totalProfit.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("মোট আদায় (পরিশোধিত)", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text("৳ ${_paidAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (val) {
              _searchQuery = val;
              _applyFilter();
            },
            decoration: InputDecoration(
              hintText: "নাম বা নম্বর দিয়ে খুঁজুন...",
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text("সকল (${_allList.length})"),
                  selected: _selectedFilter == "all",
                  onSelected: (val) {
                    _selectedFilter = "all";
                    _applyFilter();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("চলমান"),
                  selected: _selectedFilter == "pending",
                  selectedColor: Colors.amber.withAlpha(50),
                  onSelected: (val) {
                    _selectedFilter = "pending";
                    _applyFilter();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("পরিশোধিত"),
                  selected: _selectedFilter == "paid",
                  selectedColor: Colors.cyanAccent.withAlpha(50),
                  onSelected: (val) {
                    _selectedFilter = "paid";
                    _applyFilter();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _filteredList.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("কোনো হিসাব পাওয়া যায়নি!", style: TextStyle(color: AppTheme.textSecondary))))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredList.length,
                  itemBuilder: (ctx, index) {
                    final item = _filteredList[index];
                    final isPaid = item.status == 'paid';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isPaid ? Colors.cyanAccent.withAlpha(30) : AppTheme.primary.withAlpha(30),
                          child: Icon(
                            isPaid ? Icons.check_circle_outline : Icons.schedule,
                            color: isPaid ? Colors.cyanAccent : AppTheme.primary,
                          ),
                        ),
                        title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: isPaid ? TextDecoration.lineThrough : null)),
                        subtitle: Text("${item.date} • হার: ${item.profitRate}%\nঅবস্থা: ${isPaid ? 'পরিশোধিত' : 'চলমান'}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("৳ ${item.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("+৳ ${item.netProfit.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                          ],
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            color: Colors.black12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.phone.isNotEmpty) Text("ফোন: ${item.phone}", style: const TextStyle(color: Colors.white70)),
                                if (item.note.isNotEmpty) Text("নোট: ${item.note}", style: const TextStyle(color: Colors.white60)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: Icon(isPaid ? Icons.undo : Icons.done_all, color: isPaid ? Colors.amber : Colors.cyanAccent),
                                      label: Text(isPaid ? "চলমান করুন" : "পরিশোধ চিহ্নিত করুন"),
                                      onPressed: () async {
                                        await _dbHelper.toggleStatus(item.id!, item.status);
                                        _loadData();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                      onPressed: () => _showEntryDialog(editItem: item),
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
                            ),
                          )
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? "ProfitTrack BD" : "কনফিগারেশন ও সেটিংস"),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              onPressed: () => _showEntryDialog(),
              icon: const Icon(Icons.add),
              label: const Text("নতুন হিসাব", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: _currentIndex == 0
          ? _buildHomeView()
          : SettingsScreen(onDataChanged: _loadData),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withAlpha(50),
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.primary),
            label: "খতিয়ান",
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune, color: AppTheme.primary),
            label: "সেটিংস",
          ),
        ],
      ),
    );
  }
}
