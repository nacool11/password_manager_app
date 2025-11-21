import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // IMPORTANT: Update this URL based on your environment:
  // - Android Emulator: 'http://10.0.2.2:4000/api'
  // - iOS Simulator: 'http://localhost:4000/api'
  // - Physical Device: 'http://YOUR_COMPUTER_IP:4000/api' (e.g., 'http://192.168.1.100:4000/api')
  // - Web: 'http://localhost:4000/api'
  
  // Change this value to match your setup:
  static const String _baseUrl = 'http://10.0.2.2:4000/api';
  
  // Alternative URLs (uncomment the one that matches your setup):
  // static const String _baseUrl = 'http://localhost:4000/api'; // iOS Simulator / Web
  // static const String _baseUrl = 'http://192.168.1.100:4000/api'; // Physical Device (replace IP)
  
  static String get baseUrl => _baseUrl;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders({bool needsAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (needsAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<http.Response> _handleRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _getHeaders(needsAuth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await _getHeaders(needsAuth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  static Future<void> forgotPassword(String email) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: await _getHeaders(needsAuth: false),
        body: jsonEncode({'email': email}),
      );
    });

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to send OTP');
    }
  }

  static Future<void> resetPassword(String email, String otp, String newPassword) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: await _getHeaders(needsAuth: false),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );
    });

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Password reset failed');
    }
  }

  // Audit endpoint
  static Future<Map<String, dynamic>> getAudit() async {
    final response = await _handleRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/audit'),
        headers: await _getHeaders(needsAuth: true),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to get audit');
    }
  }

  // Items endpoints
  static Future<Map<String, dynamic>> getItems() async {
    final response = await _handleRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/items'),
        headers: await _getHeaders(needsAuth: true),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to get items');
    }
  }

  static Future<Map<String, dynamic>> getItem(String id) async {
    final response = await _handleRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/items/$id'),
        headers: await _getHeaders(needsAuth: true),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to get item');
    }
  }

  static Future<Map<String, dynamic>> createItem({
    required String title,
    String? subtitle,
    required String type,
    required Map<String, dynamic> data,
    String? categoryId,
  }) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/items'),
        headers: await _getHeaders(needsAuth: true),
        body: jsonEncode({
          'title': title,
          'subtitle': subtitle,
          'type': type,
          'data': data,
          'category': categoryId,
        }),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create item');
    }
  }

  static Future<Map<String, dynamic>> updateItem(
    String id, {
    String? title,
    String? subtitle,
    String? type,
    Map<String, dynamic>? data,
    String? categoryId,
  }) async {
    final response = await _handleRequest(() async {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (subtitle != null) body['subtitle'] = subtitle;
      if (type != null) body['type'] = type;
      if (data != null) body['data'] = data;
      if (categoryId != null) body['category'] = categoryId;

      return await http.put(
        Uri.parse('$baseUrl/items/$id'),
        headers: await _getHeaders(needsAuth: true),
        body: jsonEncode(body),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update item');
    }
  }

  static Future<void> deleteItem(String id) async {
    final response = await _handleRequest(() async {
      return await http.delete(
        Uri.parse('$baseUrl/items/$id'),
        headers: await _getHeaders(needsAuth: true),
      );
    });

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete item');
    }
  }

  // Categories endpoints
  static Future<Map<String, dynamic>> getCategories() async {
    final response = await _handleRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: await _getHeaders(needsAuth: true),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to get categories');
    }
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    String? icon,
    String? color,
  }) async {
    final response = await _handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: await _getHeaders(needsAuth: true),
        body: jsonEncode({
          'name': name,
          'icon': icon,
          'color': color,
        }),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create category');
    }
  }

  static Future<Map<String, dynamic>> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? color,
  }) async {
    final response = await _handleRequest(() async {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (icon != null) body['icon'] = icon;
      if (color != null) body['color'] = color;

      return await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: await _getHeaders(needsAuth: true),
        body: jsonEncode(body),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update category');
    }
  }

  static Future<void> deleteCategory(String id) async {
    final response = await _handleRequest(() async {
      return await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: await _getHeaders(needsAuth: true),
      );
    });

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete category');
    }
  }

  // Settings endpoints
  static Future<Map<String, dynamic>> getSettings() async {
    final response = await _handleRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: await _getHeaders(needsAuth: true),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to get settings');
    }
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final response = await _handleRequest(() async {
      return await http.put(
        Uri.parse('$baseUrl/settings'),
        headers: await _getHeaders(needsAuth: true),
        body: jsonEncode(settings),
      );
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update settings');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

