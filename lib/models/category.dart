import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final String type; // 'income' | 'expense'
  final int colorValue;
  final int iconCode;
  final int? parentId;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    required this.iconCode,
    this.parentId,
  });

  Color get color => Color(colorValue);
  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Category copyWith({String? name, String? type, int? colorValue, int? iconCode, int? parentId}) {
    return Category(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
      parentId: parentId ?? this.parentId,
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'type': type,
    'color': colorValue,
    'icon': iconCode,
    'parent_id': parentId,
  };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
    id:         (m['id']   as num?)?.toInt(),
    name:       m['name']  as String,
    type:       m['type']  as String,
    colorValue: (m['color'] as num).toInt(),
    iconCode:   (m['icon']  as num).toInt(),
    parentId:   (m['parent_id'] as num?)?.toInt(),
  );
}
