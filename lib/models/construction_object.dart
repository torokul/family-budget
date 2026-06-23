class ConstructionObject {
  final int? id;
  final String name;
  final String? description;
  final bool isActive;
  final int sortOrder;

  const ConstructionObject({
    this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'is_active': isActive ? 1 : 0,
    'sort_order': sortOrder,
  };

  factory ConstructionObject.fromMap(Map<String, dynamic> m) => ConstructionObject(
    id:          (m['id'] as num?)?.toInt(),
    name:        m['name'] as String,
    description: m['description'] as String?,
    isActive:    ((m['is_active'] as num?)?.toInt() ?? 1) != 0,
    sortOrder:   (m['sort_order'] as num?)?.toInt() ?? 0,
  );

  ConstructionObject copyWith({String? name, String? description, bool? isActive}) =>
      ConstructionObject(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder,
      );
}
