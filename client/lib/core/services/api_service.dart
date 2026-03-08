import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your server URL
  static const String baseUrl = 'http://192.168.11.117:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000'; // iOS simulator
  // static const String baseUrl = 'http://YOUR_IP:5000'; // Physical device

  String? _token;

  void setToken(String? token) {
    print('[API] Token ${token != null ? "set" : "cleared"}');
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<ApiResponse> post(String endpoint, Map<String, dynamic> body) async {
    print('[API] POST $baseUrl$endpoint');
    print('[API] Headers: ${_headers.keys.toList()}');
    print('[API] Body: ${body.keys.toList()}');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      print('[API] Response: ${response.statusCode}');
      print('[API] Response body: ${response.body}');
      return ApiResponse.fromResponse(response);
    } catch (e) {
      print('[API] POST Error: $e');
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> get(String endpoint) async {
    print('[API] GET $baseUrl$endpoint');
    print('[API] Headers: ${_headers.keys.toList()}');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      print('[API] Response: ${response.statusCode}');
      print('[API] Response body: ${response.body}');
      return ApiResponse.fromResponse(response);
    } catch (e) {
      print('[API] GET Error: $e');
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      return ApiResponse.fromResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}

class ApiResponse {
  final bool success;
  final int statusCode;
  final String? message;
  final Map<String, dynamic>? data;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.message,
    this.data,
  });

  factory ApiResponse.fromResponse(http.Response response) {
    Map<String, dynamic>? data;
    String? message;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
      message = data['message'] as String?;
    } catch (_) {
      message = response.body;
    }

    return ApiResponse(
      success: response.statusCode >= 200 && response.statusCode < 300,
      statusCode: response.statusCode,
      message: message,
      data: data,
    );
  }
}
