import 'package:flutter/material.dart';

class Group {
  final int? id;
  final String name;
  final int iconCode;
  final int colorValue;
  final int sortOrder;
  final String type; // 'expense' | 'income' | 'mixed'

  const Group({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.sortOrder = 0,
    this.type = 'expense',
  });

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'icon': iconCode,
    'color': colorValue,
    'sort_order': sortOrder,
    'type': type,
  };

  factory Group.fromMap(Map<String, dynamic> m) => Group(
    id:         (m['id'] as num?)?.toInt(),
    name:       m['name'] as String,
    iconCode:   (m['icon'] as num).toInt(),
    colorValue: (m['color'] as num).toInt(),
    sortOrder:  (m['sort_order'] as num?)?.toInt() ?? 0,
    type:       m['type'] as String? ?? 'expense',
  );

  Group copyWith({String? name, int? iconCode, int? colorValue, int? sortOrder, String? type}) =>
      Group(
        id: id,
        name: name ?? this.name,
        iconCode: iconCode ?? this.iconCode,
        colorValue: colorValue ?? this.colorValue,
        sortOrder: sortOrder ?? this.sortOrder,
        type: type ?? this.type,
      );
}
