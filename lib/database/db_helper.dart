import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TransactionItem {
  final int? id;
  final String title;
  final String phone;
  final double amount;
  final double profitRate;
  final double netProfit;
  final String date;
  final String status;
  final String note;

  TransactionItem({
    this.id,
    required this.title,
    this.phone = '',
    required this.amount,
    required this.profitRate,
    required this.netProfit,
    required this.date,
    this.status = 'pending',
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'phone': phone,
      'amount': amount,
      'profitRate': profitRate,
      'netProfit': netProfit,
      'date': date,
      'status': status,
      'note': note,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      title: map['title'] ?? '',
      phone: map['phone'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      profitRate: (map['profitRate'] as num).toDouble(),
      netProfit: (map['netProfit'] as num).toDouble(),
      date: map['date'] ?? '',
      status: map['status'] ?? 'pending',
      note: map['note'] ?? '',
    );
  }
}

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'profittrack_v3.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            phone TEXT,
            amount REAL,
            profitRate REAL,
            netProfit REAL,
            date TEXT,
            status TEXT,
            note TEXT
          )
        ''');
      },
    );
  }

  Future<int> insert(TransactionItem item) async {
    final db = await database;
    return await db.insert('transactions', item.toMap());
  }

  Future<int> update(TransactionItem item) async {
    final db = await database;
    return await db.update('transactions', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<List<TransactionItem>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => TransactionItem.fromMap(maps[i]));
  }

  Future<int> toggleStatus(int id, String currentStatus) async {
    final db = await database;
    final newStatus = currentStatus == 'pending' ? 'paid' : 'pending';
    return await db.update('transactions', {'status': newStatus}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
  }
}
