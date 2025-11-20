import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/user.dart';
import '../models/user_settings.dart';
import '../models/vault_item.dart';
import '../services/api_client.dart';

class SessionManager extends ChangeNotifier {
  SessionManager({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _bootstrap();
  }

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final ApiClient _apiClient;
  SharedPreferences? _prefs;

  String? _token;
  UserModel? _user;
  UserSettings _settings = const UserSettings();
  List<VaultItem> _items = const [];
  List<CategoryModel> _categories = const [];

  bool _initialized = false;
  bool _authInFlight = false;
  bool _vaultLoading = false;
  bool _settingsSaving = false;
  bool _hasLoadedVault = false;

  String? _lastError;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get authInProgress => _authInFlight;
  bool get vaultLoading => _vaultLoading;
  bool get settingsSaving => _settingsSaving;
  String? get lastError => _lastError;

  UserModel? get user => _user;
  UserSettings get settings => _settings;
  List<VaultItem> get items => List.unmodifiable(_items);
  List<CategoryModel> get categories => List.unmodifiable(_categories);

  Future<void> _bootstrap() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString(_tokenKey);
    _user = UserModel.fromRawJson(_prefs?.getString(_userKey));
    _settings = _user?.settings ?? const UserSettings();
    if (isAuthenticated) {
      try {
        await refreshVaultData();
      } catch (_) {
        await logout();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    return _authenticate(
      path: '/auth/login',
      payload: {'email': email, 'password': password},
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    return _authenticate(
      path: '/auth/register',
      payload: {'email': email, 'password': password},
    );
  }

  Future<void> _authenticate({
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    _lastError = null;
    _authInFlight = true;
    notifyListeners();
    try {
      final response = await _apiClient.post(path, body: payload);
      final token = response['token']?.toString();
      final userJson = response['user'] as Map<String, dynamic>?;
      if (token == null || userJson == null) {
        throw const ApiException('Invalid response from server');
      }
      _token = token;
      _user = UserModel.fromJson(userJson);
      _settings = _user!.settings;
      await _persistSession();
      await refreshVaultData();
    } on ApiException catch (err) {
      _lastError = err.message;
      rethrow;
    } finally {
      _authInFlight = false;
      notifyListeners();
    }
  }

  Future<void> refreshVaultData() async {
    if (!isAuthenticated) return;
    _vaultLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _apiClient.get('/items', token: _token),
        _apiClient.get('/categories', token: _token),
        _apiClient.get('/settings', token: _token),
      ]);
      final itemsPayload = results[0] as Map<String, dynamic>? ?? {};
      final categoriesPayload = results[1] as Map<String, dynamic>? ?? {};
      final settingsPayload = results[2] as Map<String, dynamic>? ?? {};

      _items = (itemsPayload['items'] as List<dynamic>? ?? [])
          .map((e) => VaultItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _categories = (categoriesPayload['categories'] as List<dynamic>? ?? [])
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _settings =
          UserSettings.fromJson(settingsPayload['settings'] as Map<String, dynamic>?);

      if (_user != null) {
        _user = _user!.copyWith(settings: _settings);
        await _prefs?.setString(_userKey, _user!.toRawJson());
      }
      _hasLoadedVault = true;
    } on ApiException catch (err) {
      _lastError = err.message;
      if (err.statusCode == 401) {
        await logout();
      } else {
        rethrow;
      }
    } finally {
      _vaultLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureVaultLoaded() async {
    if (_hasLoadedVault || !isAuthenticated) return;
    await refreshVaultData();
  }

  Future<void> createItem({
    required String title,
    String? subtitle,
    required String type,
    required Map<String, dynamic> data,
    String? categoryId,
  }) async {
    if (!isAuthenticated) return;
    await _apiClient.post(
      '/items',
      token: _token,
      body: {
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'data': data,
        'category': categoryId,
      },
    );
    await refreshVaultData();
  }

  Future<void> deleteItem(String id) async {
    if (!isAuthenticated) return;
    await _apiClient.delete('/items/$id', token: _token);
    _items = _items.where((item) => item.id != id).toList();
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    if (!isAuthenticated) return;
    await _apiClient.post(
      '/categories',
      token: _token,
      body: {'name': name},
    );
    await refreshVaultData();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    if (!isAuthenticated) return;
    _settingsSaving = true;
    notifyListeners();
    try {
      final response = await _apiClient.put(
        '/settings',
        token: _token,
        body: newSettings.toJson(),
      );
      _settings =
          UserSettings.fromJson(response['settings'] as Map<String, dynamic>?);
      if (_user != null) {
        _user = _user!.copyWith(settings: _settings);
        await _prefs?.setString(_userKey, _user!.toRawJson());
      }
      notifyListeners();
    } finally {
      _settingsSaving = false;
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset(String email) {
    return _apiClient.post(
      '/auth/forgot-password',
      body: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) {
    return _apiClient.post(
      '/auth/reset-password',
      body: {
        'email': email,
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _items = const [];
    _categories = const [];
    _settings = const UserSettings();
    _hasLoadedVault = false;
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userKey);
    notifyListeners();
  }

  Future<void> _persistSession() async {
    if (_token != null) {
      await _prefs?.setString(_tokenKey, _token!);
    }
    if (_user != null) {
      await _prefs?.setString(_userKey, _user!.toRawJson());
    }
  }
}

