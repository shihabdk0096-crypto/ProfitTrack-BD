class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final double profitRate;
  final double netProfit;
  final String date;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.profitRate,
    required this.netProfit,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'profitRate': profitRate,
      'netProfit': netProfit,
      'date': date,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      profitRate: map['profitRate'],
      netProfit: map['netProfit'],
      date: map['date'],
    );
  }
}
