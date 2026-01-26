import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  String get baseUrl => EnvConfig.apiUrl;

  Map<String, String> _getHeaders(
      {bool includeAuth = true, bool isJson = true}) {
    final headers = <String, String>{};

    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    // BYPASS LOCALTUNNEL/NGROK LANDING PAGES
    headers['Bypass-Tunnel-Reminder'] = 'true';
    headers['ngrok-skip-browser-warning'] = 'true';

    return headers;
  }

  Future<dynamic> get(String endpoint,
      {Map<String, String>? params, bool requireAuth = true}) async {
    try {
      var url = Uri.parse('$baseUrl$endpoint');
      if (params != null) {
        url = url.replace(queryParameters: params);
      }

      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: requireAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> post(
    String endpoint,
    dynamic body, {
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('🚀 [API POST] $url');
      print('📦 [API BODY] ${jsonEncode(body)}');

      final response = await http
          .post(
            url,
            headers: _getHeaders(includeAuth: requireAuth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('✅ [API RESPONSE] ${response.statusCode} - ${response.body}');
      return _handleResponse(response);
    } catch (e, stack) {
      print('❌ [API ERROR] $e');
      print('📜 [STACK TRACE] $stack');
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> put(
    String endpoint,
    dynamic body, {
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        url,
        headers: _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> patch(
    String endpoint,
    dynamic body, {
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.patch(
        url,
        headers: _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(
        url,
        headers: _getHeaders(includeAuth: requireAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> postMultipart(
    String endpoint,
    Map<String, String> fields,
    File? file, {
    String fileFieldName = 'image',
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', url);

      // Add headers
      if (requireAuth && _authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Add fields
      request.fields.addAll(fields);

      // Add file if provided
      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileFieldName, file.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'message': response.body};
      }
    } else if (statusCode == 401) {
      throw ApiException('Unauthorized. Please login again.', statusCode: 401);
    } else if (statusCode == 403) {
      throw ApiException('Access forbidden.', statusCode: 403);
    } else if (statusCode == 404) {
      throw ApiException('Resource not found.', statusCode: 404);
    } else if (statusCode >= 500) {
      throw ApiException('Server error. Please try again later.',
          statusCode: statusCode);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final message = (errorData as Map<String, dynamic>)['error'] ??
            errorData['message'] ??
            'Unknown error';
        throw ApiException(message, statusCode: statusCode);
      } catch (e) {
        throw ApiException('Request failed with status $statusCode',
            statusCode: statusCode);
      }
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
