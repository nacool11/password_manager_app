class UserSettings {
  const UserSettings({
    this.darkMode = false,
    this.largeFont = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserSettings();
    }
    return UserSettings(
      darkMode: json['darkMode'] == true,
      largeFont: json['largeFont'] == true,
    );
  }

  final bool darkMode;
  final bool largeFont;

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        'largeFont': largeFont,
      };

  UserSettings copyWith({
    bool? darkMode,
    bool? largeFont,
  }) {
    return UserSettings(
      darkMode: darkMode ?? this.darkMode,
      largeFont: largeFont ?? this.largeFont,
    );
  }
}

