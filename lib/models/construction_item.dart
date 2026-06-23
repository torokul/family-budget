class ConstructionItem {
  final int? id;
  final int sectionId;
  final String name;
  final String unit;
  final double planAmount;
  final int sortOrder;

  const ConstructionItem({
    this.id,
    required this.sectionId,
    required this.name,
    this.unit = 'шт',
    this.planAmount = 0,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'section_id': sectionId,
    'name': name,
    'unit': unit,
    'plan_amount': planAmount,
    'sort_order': sortOrder,
  };

  factory ConstructionItem.fromMap(Map<String, dynamic> m) => ConstructionItem(
    id:         (m['id'] as num?)?.toInt(),
    sectionId:  (m['section_id'] as num).toInt(),
    name:       m['name'] as String,
    unit:       m['unit'] as String? ?? 'шт',
    planAmount: (m['plan_amount'] as num?)?.toDouble() ?? 0,
    sortOrder:  (m['sort_order'] as num?)?.toInt() ?? 0,
  );

  ConstructionItem copyWith({String? name, String? unit, double? planAmount}) =>
      ConstructionItem(
        id: id, sectionId: sectionId,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        planAmount: planAmount ?? this.planAmount,
        sortOrder: sortOrder,
      );
}
