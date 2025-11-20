class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
    );
  }

  final String id;
  final String name;
  final String? icon;
  final String? color;
}

