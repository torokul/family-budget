class Plan {
  final int? id;
  final int? categoryId; // null = group-level plan
  final int? groupId;    // null = category-level plan
  final double amount;
  final String periodType; // 'month' | 'quarter' | 'year'
  final int year;
  final int? month; // 1-12 for month, 1-4 for quarter, null for year
  // joined
  final String? categoryName;
  final String? groupName;

  const Plan({
    this.id,
    this.categoryId,
    this.groupId,
    required this.amount,
    this.periodType = 'month',
    required this.year,
    this.month,
    this.categoryName,
    this.groupName,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category_id': categoryId,
    'group_id': groupId,
    'amount': amount,
    'period_type': periodType,
    'year': year,
    'month': month,
  };

  factory Plan.fromMap(Map<String, dynamic> m) => Plan(
    id:           (m['id'] as num?)?.toInt(),
    categoryId:   (m['category_id'] as num?)?.toInt(),
    groupId:      (m['group_id'] as num?)?.toInt(),
    amount:       (m['amount'] as num).toDouble(),
    periodType:   m['period_type'] as String? ?? 'month',
    year:         (m['year'] as num).toInt(),
    month:        (m['month'] as num?)?.toInt(),
    categoryName: m['cat_name'] as String?,
    groupName:    m['grp_name'] as String?,
  );
}
