import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PaymentLog {
  final int? id;
  final int transactionId;
  final double amount;
  final String paymentDate;
  final int monthCount;

  PaymentLog({
    this.id,
    required this.transactionId,
    required this.amount,
    required this.paymentDate,
    required this.monthCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'amount': amount,
      'paymentDate': paymentDate,
      'monthCount': monthCount,
    };
  }

  factory PaymentLog.fromMap(Map<String, dynamic> map) {
    return PaymentLog(
      id: map['id'],
      transactionId: map['transactionId'],
      amount: (map['amount'] as num).toDouble(),
      paymentDate: map['paymentDate'] ?? '',
      monthCount: map['monthCount'] ?? 1,
    );
  }
}

class TransactionItem {
  final int? id;
  final String title;
  final String phone;
  final double amount;
  final double profitRate;
  final double monthlyProfit;
  final String startDate;
  final int paidMonths;
  final String lastPaymentDate;
  final String note;

  TransactionItem({
    this.id,
    required this.title,
    this.phone = '',
    required this.amount,
    required this.profitRate,
    required this.monthlyProfit,
    required this.startDate,
    this.paidMonths = 0,
    this.lastPaymentDate = '',
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'phone': phone,
      'amount': amount,
      'profitRate': profitRate,
      'monthlyProfit': monthlyProfit,
      'startDate': startDate,
      'paidMonths': paidMonths,
      'lastPaymentDate': lastPaymentDate,
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
      monthlyProfit: (map['monthlyProfit'] as num).toDouble(),
      startDate: map['startDate'] ?? '',
      paidMonths: map['paidMonths'] ?? 0,
      lastPaymentDate: map['lastPaymentDate'] ?? '',
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
    String path = join(await getDatabasesPath(), 'profittrack_v4.db');
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
            monthlyProfit REAL,
            startDate TEXT,
            paidMonths INTEGER,
            lastPaymentDate TEXT,
            note TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE payment_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transactionId INTEGER,
            amount REAL,
            paymentDate TEXT,
            monthCount INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insert(TransactionItem item) async {
    final db = await database;
    return await db.insert('transactions', item.toMap());
  }

  Future<List<TransactionItem>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => TransactionItem.fromMap(maps[i]));
  }

  Future<void> addProfitPayment(int transId, int currentPaidMonths, int addingMonths, double totalAmount) async {
    final db = await database;
    final now = DateTime.now().toString().substring(0, 10);
    await db.insert('payment_logs', {
      'transactionId': transId,
      'amount': totalAmount,
      'paymentDate': now,
      'monthCount': addingMonths,
    });

    await db.update(
      'transactions',
      {
        'paidMonths': currentPaidMonths + addingMonths,
        'lastPaymentDate': now,
      },
      where: 'id = ?',
      whereArgs: [transId],
    );
  }

  Future<List<PaymentLog>> getLogs(int transId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_logs',
      where: 'transactionId = ?',
      whereArgs: [transId],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => PaymentLog.fromMap(maps[i]));
  }

  Future<int> delete(int id) async {
    final db = await database;
    await db.delete('payment_logs', where: 'transactionId = ?', whereArgs: [id]);
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('payment_logs');
    await db.delete('transactions');
  }
}
