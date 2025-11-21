class VaultItem {
  final String id;
  final String title;
  final String? subtitle;
  final String type;
  final Map<String, dynamic>? data;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.data,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCard => type == 'card' || type == 'credit_card';
  bool get isPassword => type == 'password' || type == 'login';

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      type: json['type'] ?? 'password',
      data: json['data'],
      categoryId: json['category'] ?? json['categoryId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'data': data,
      'category': categoryId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

