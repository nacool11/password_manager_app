import 'dart:convert';

import 'user_settings.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.settings = const UserSettings(),
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      settings: UserSettings.fromJson(json['settings'] as Map<String, dynamic>?),
    );
  }

  final String id;
  final String email;
  final UserSettings settings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'settings': settings.toJson(),
      };

  String toRawJson() => jsonEncode(toJson());

  static UserModel? fromRawJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return UserModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    UserSettings? settings,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      settings: settings ?? this.settings,
    );
  }
}

