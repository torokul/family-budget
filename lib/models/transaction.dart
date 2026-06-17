class Transaction {
  final int? id;
  final String type; // 'income' | 'expense'
  final double amount;
  final String currency; // 'KGS' | 'USD' | 'EUR' | 'RUB'
  final int categoryId;
  final DateTime date;
  final String? comment;
  final String? receiptBase64;
  // joined
  final String? categoryName;
  final int? categoryColor;
  final int? categoryIcon;

  const Transaction({
    this.id,
    required this.type,
    required this.amount,
    this.currency = 'KGS',
    required this.categoryId,
    required this.date,
    this.comment,
    this.receiptBase64,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'type': type,
    'amount': amount,
    'currency': currency,
    'category_id': categoryId,
    'date': date.toIso8601String(),
    'comment': comment,
    'receipt': receiptBase64,
  };

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
    id:            (m['id'] as num?)?.toInt(),
    type:          m['type'] as String,
    amount:        (m['amount'] as num).toDouble(),
    currency:      m['currency'] as String? ?? 'KGS',
    categoryId:    (m['category_id'] as num).toInt(),
    date:          DateTime.parse(m['date'] as String),
    comment:       m['comment'] as String?,
    receiptBase64: m['receipt'] as String?,
    categoryName:  m['cat_name'] as String?,
    categoryColor: (m['cat_color'] as num?)?.toInt(),
    categoryIcon:  (m['cat_icon'] as num?)?.toInt(),
  );
}
