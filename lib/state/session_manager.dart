import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault_item.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';

class UserSettings {
  final bool darkMode;
  final bool largeFont;

  UserSettings({
    this.darkMode = false,
    this.largeFont = false,
  });

  UserSettings copyWith({
    bool? darkMode,
    bool? largeFont,
  }) {
    return UserSettings(
      darkMode: darkMode ?? this.darkMode,
      largeFont: largeFont ?? this.largeFont,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      darkMode: json['darkMode'] ?? false,
      largeFont: json['largeFont'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'largeFont': largeFont,
    };
  }
}

class SessionManager extends ChangeNotifier {
  List<VaultItem> _items = [];
  List<CategoryModel> _categories = [];
  UserSettings _settings = UserSettings();
  bool _settingsSaving = false;
  bool _loading = false;

  List<VaultItem> get items => _items;
  List<CategoryModel> get categories => _categories;
  UserSettings get settings => _settings;
  bool get settingsSaving => _settingsSaving;
  bool get loading => _loading;

  Future<void> ensureVaultLoaded() async {
    if (_loading) return;
    await loadVault();
  }

  Future<void> loadVault() async {
    _loading = true;
    notifyListeners();

    try {
      // Load items
      final itemsResponse = await ApiService.getItems();
      final itemsList = (itemsResponse['items'] as List?)
              ?.map((json) => VaultItem.fromJson(json))
              .toList() ??
          [];
      _items = itemsList;

      // Load categories
      final categoriesResponse = await ApiService.getCategories();
      final categoriesList = (categoriesResponse['categories'] as List?)
              ?.map((json) => CategoryModel.fromJson(json))
              .toList() ??
          [];
      _categories = categoriesList;

      // Load settings
      try {
        final settingsResponse = await ApiService.getSettings();
        _settings = UserSettings.fromJson(settingsResponse['settings'] ?? {});
      } catch (e) {
        // Settings might not exist yet, use defaults
        _settings = UserSettings();
      }
    } catch (e) {
      debugPrint('Error loading vault: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createItem({
    required String title,
    String? subtitle,
    required String type,
    required Map<String, dynamic> data,
    String? categoryId,
  }) async {
    try {
      await ApiService.createItem(
        title: title,
        subtitle: subtitle,
        type: type,
        data: data,
        categoryId: categoryId,
      );
      await loadVault(); // Reload to get the new item
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateItem(
    String id, {
    String? title,
    String? subtitle,
    String? type,
    Map<String, dynamic>? data,
    String? categoryId,
  }) async {
    try {
      await ApiService.updateItem(
        id,
        title: title,
        subtitle: subtitle,
        type: type,
        data: data,
        categoryId: categoryId,
      );
      await loadVault();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await ApiService.deleteItem(id);
      await loadVault();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createCategory({
    required String name,
    String? icon,
    String? color,
  }) async {
    try {
      await ApiService.createCategory(
        name: name,
        icon: icon,
        color: color,
      );
      await loadVault();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? color,
  }) async {
    try {
      await ApiService.updateCategory(
        id,
        name: name,
        icon: icon,
        color: color,
      );
      await loadVault();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await ApiService.deleteCategory(id);
      await loadVault();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    _settingsSaving = true;
    notifyListeners();

    try {
      await ApiService.updateSettings(newSettings.toJson());
      _settings = newSettings;
    } catch (e) {
      debugPrint('Error updating settings: $e');
      rethrow;
    } finally {
      _settingsSaving = false;
      notifyListeners();
    }
  }
}

