class VaultItem {
  const VaultItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.data,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      type: json['type']?.toString() ?? 'password',
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      categoryId: json['category']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final String type;
  final Map<String, dynamic>? data;
  final String? categoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCard => type == 'card';
  bool get isPassword => type == 'password' || type == 'login';
}

