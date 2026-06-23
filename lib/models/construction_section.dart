import 'package:flutter/material.dart';

class ConstructionSection {
  final int? id;
  final int objectId;
  final String name;
  final double planAmount;
  final int iconCode;
  final int colorValue;
  final int sortOrder;

  const ConstructionSection({
    this.id,
    required this.objectId,
    required this.name,
    this.planAmount = 0,
    required this.iconCode,
    required this.colorValue,
    this.sortOrder = 0,
  });

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'object_id': objectId,
    'name': name,
    'plan_amount': planAmount,
    'icon': iconCode,
    'color': colorValue,
    'sort_order': sortOrder,
  };

  factory ConstructionSection.fromMap(Map<String, dynamic> m) => ConstructionSection(
    id:          (m['id'] as num?)?.toInt(),
    objectId:    (m['object_id'] as num?)?.toInt() ?? 1,
    name:        m['name'] as String,
    planAmount:  (m['plan_amount'] as num?)?.toDouble() ?? 0,
    iconCode:    (m['icon'] as num).toInt(),
    colorValue:  (m['color'] as num).toInt(),
    sortOrder:   (m['sort_order'] as num?)?.toInt() ?? 0,
  );

  ConstructionSection copyWith({String? name, double? planAmount, int? iconCode, int? colorValue}) =>
      ConstructionSection(
        id: id,
        objectId: objectId,
        name: name ?? this.name,
        planAmount: planAmount ?? this.planAmount,
        iconCode: iconCode ?? this.iconCode,
        colorValue: colorValue ?? this.colorValue,
        sortOrder: sortOrder,
      );
}
