// category.dart
// Represents a product category in the Vynex catalog.

class Category {
  final int? id;
  final String name;
  final String colorHex;
  final String iconName;
  final bool isPredefined;
  final int sortOrder;

  const Category({
    this.id,
    required this.name,
    this.colorHex = 'FFD700',
    this.iconName = 'category',
    this.isPredefined = false,
    this.sortOrder = 0,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String? ?? 'FFD700',
      iconName: map['icon_name'] as String? ?? 'category',
      isPredefined: (map['is_predefined'] as int?) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon_name': iconName,
      'is_predefined': isPredefined ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? iconName,
    bool? isPredefined,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isPredefined: isPredefined ?? this.isPredefined,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() =>
      'Category(id: $id, name: $name, '
      'predefined: $isPredefined)';
}
