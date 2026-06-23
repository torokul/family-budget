class ConstructionExpense {
  final int? id;
  final int itemId;
  final double qty;
  final String unit;
  final double price;
  final double amount;
  final String currency;
  final String? description;
  final DateTime? date;

  const ConstructionExpense({
    this.id,
    required this.itemId,
    this.qty = 1,
    this.unit = 'шт',
    this.price = 0,
    required this.amount,
    this.currency = 'KGS',
    this.description,
    this.date,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'item_id': itemId,
    'qty': qty,
    'unit': unit,
    'price': price,
    'amount': amount,
    'currency': currency,
    'description': description,
    'date': date?.toIso8601String(),
  };

  factory ConstructionExpense.fromMap(Map<String, dynamic> m) => ConstructionExpense(
    id:          (m['id'] as num?)?.toInt(),
    itemId:      (m['item_id'] as num).toInt(),
    qty:         (m['qty'] as num?)?.toDouble() ?? 1,
    unit:        m['unit'] as String? ?? 'шт',
    price:       (m['price'] as num?)?.toDouble() ?? 0,
    amount:      (m['amount'] as num).toDouble(),
    currency:    m['currency'] as String? ?? 'KGS',
    description: m['description'] as String?,
    date:        m['date'] != null ? DateTime.tryParse(m['date'] as String) : null,
  );

  ConstructionExpense copyWith({
    double? qty, String? unit, double? price, double? amount,
    String? currency, String? description, DateTime? date,
  }) => ConstructionExpense(
    id: id, itemId: itemId,
    qty: qty ?? this.qty,
    unit: unit ?? this.unit,
    price: price ?? this.price,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    description: description ?? this.description,
    date: date ?? this.date,
  );
}
