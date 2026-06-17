class BudgetLimit {
  final int? id;
  final int categoryId;
  final int month;
  final int year;
  final double limitAmount;
  final String? categoryName;
  final int? categoryColor;

  const BudgetLimit({
    this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.limitAmount,
    this.categoryName,
    this.categoryColor,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category_id': categoryId,
    'month': month,
    'year': year,
    'limit_amount': limitAmount,
  };

  factory BudgetLimit.fromMap(Map<String, dynamic> m) => BudgetLimit(
    id:           (m['id'] as num?)?.toInt(),
    categoryId:   (m['category_id'] as num).toInt(),
    month:        (m['month'] as num).toInt(),
    year:         (m['year'] as num).toInt(),
    limitAmount:  (m['limit_amount'] as num).toDouble(),
    categoryName: m['cat_name'] as String?,
    categoryColor:(m['cat_color'] as num?)?.toInt(),
  );
}
