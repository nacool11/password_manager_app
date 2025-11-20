import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<dynamic> get(
    String path, {
    String? token,
    Map<String, dynamic>? query,
  }) {
    return _send(
      method: 'GET',
      path: path,
      token: token,
      query: query,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return _send(
      method: 'POST',
      path: path,
      token: token,
      body: body,
    );
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return _send(
      method: 'PUT',
      path: path,
      token: token,
      body: body,
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      token: token,
      body: body,
    );
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    String? token,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path, query);
    final request = http.Request(method, uri);
    request.headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final response =
        await _client.send(request).timeout(kApiTimeout);
    final payload = await response.stream.bytesToString();
    return _handleResponse(response, payload);
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final sanitizedPath =
        path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$sanitizedPath')
        .replace(queryParameters: query?.map(
      (key, value) => MapEntry(
        key,
        value?.toString(),
      ),
    ));
  }

  dynamic _handleResponse(http.StreamedResponse response, String body) {
    final status = response.statusCode;
    dynamic jsonBody;
    if (body.isNotEmpty) {
      try {
        jsonBody = jsonDecode(body);
      } catch (_) {
        jsonBody = body;
      }
    }
    if (status >= 200 && status < 300) {
      return jsonBody;
    }
    final message = jsonBody is Map<String, dynamic> && jsonBody['message'] != null
        ? jsonBody['message'].toString()
        : 'Request failed ($status)';
    throw ApiException(message, statusCode: status);
  }
}

