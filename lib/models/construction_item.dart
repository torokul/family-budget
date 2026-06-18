class ConstructionItem {
  final int? id;
  final int sectionId;
  final String name;
  final double qty;
  final double price;
  final double amount;
  final String? description;
  final DateTime? date;

  const ConstructionItem({
    this.id,
    required this.sectionId,
    required this.name,
    this.qty = 1,
    this.price = 0,
    required this.amount,
    this.description,
    this.date,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'section_id': sectionId,
    'name': name,
    'qty': qty,
    'price': price,
    'amount': amount,
    'description': description,
    'date': date?.toIso8601String(),
  };

  factory ConstructionItem.fromMap(Map<String, dynamic> m) => ConstructionItem(
    id:          (m['id'] as num?)?.toInt(),
    sectionId:   (m['section_id'] as num).toInt(),
    name:        m['name'] as String,
    qty:         (m['qty'] as num?)?.toDouble() ?? 1,
    price:       (m['price'] as num?)?.toDouble() ?? 0,
    amount:      (m['amount'] as num).toDouble(),
    description: m['description'] as String?,
    date:        m['date'] != null ? DateTime.tryParse(m['date'] as String) : null,
  );

  ConstructionItem copyWith({
    String? name, double? qty, double? price, double? amount,
    String? description, DateTime? date,
  }) => ConstructionItem(
    id: id, sectionId: sectionId,
    name: name ?? this.name,
    qty: qty ?? this.qty,
    price: price ?? this.price,
    amount: amount ?? this.amount,
    description: description ?? this.description,
    date: date ?? this.date,
  );
}
