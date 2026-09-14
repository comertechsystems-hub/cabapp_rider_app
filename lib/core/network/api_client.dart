import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../storage/session_manager.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode = 500, this.details});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Abstract contract for API client operations
abstract class IApiClient {
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams});
  Future<dynamic> post(String path, {Map<String, dynamic>? body});
}

class ApiClient implements IApiClient {
  final String baseUrl;
  final SessionManager? sessionManager;
  final http.Client _client;

  ApiClient({
    this.baseUrl = ApiEndpoints.defaultBaseUrl,
    this.sessionManager,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final auth = sessionManager?.authHeader;
    if (auth != null) {
      headers['Authorization'] = auth;
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())),
    );
    final response = await _client.get(uri, headers: _buildHeaders());
    return _handleResponse(response);
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: _buildHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
      return data;
    }

    String errorMsg = 'HTTP ${response.statusCode} Request Failed';
    try {
      final errorJson = jsonDecode(response.body);
      if (errorJson is Map<String, dynamic>) {
        if (errorJson.containsKey('exception')) {
          errorMsg = errorJson['exception'].toString();
        } else if (errorJson.containsKey('message')) {
          errorMsg = errorJson['message'].toString();
        }
      }
    } catch (_) {}

    throw ApiException(errorMsg, statusCode: response.statusCode);
  }
}

/// In-memory mock API client for unit testing without live network
class MockApiClient implements IApiClient {
  final Map<String, dynamic> responses = {};
  final List<Map<String, dynamic>> callLogs = [];

  void setResponse(String path, dynamic response) {
    responses[path] = response;
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    callLogs.add({'method': 'GET', 'path': path, 'queryParams': queryParams});
    if (responses.containsKey(path)) {
      final res = responses[path];
      if (res is Exception) throw res;
      return res;
    }
    return {'success': true};
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    callLogs.add({'method': 'POST', 'path': path, 'body': body});
    if (responses.containsKey(path)) {
      final res = responses[path];
      if (res is Exception) throw res;
      return res;
    }
    return {'success': true};
  }
}
