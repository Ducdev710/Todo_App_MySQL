// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_item.dart';
import '../models/user.dart';
import '../utils/date_utils.dart';

class ApiService {
  // ✅ SMART BASE URL với SSL bypass
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://localhost:7215';
    } else if (Platform.isAndroid) {
      return 'https://10.0.2.2:7215';
    } else {
      return 'https://localhost:7215';
    }
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final http.Client _httpClient;
  String? _token;

  // ✅ GETTERS cho token management
  String? get token => _token;
  bool get hasToken => _token != null;
  bool get isAuthenticated => _token != null;

  void init() {
    // ✅ SSL bypass cho development
    HttpOverrides.global = _DevHttpOverrides();
    _httpClient = http.Client();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ✅ TOKEN MANAGEMENT
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('🔑 Token saved successfully');
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    print('🔑 Token loaded: ${_token != null ? 'Present' : 'Not found'}');
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    await loadToken();
    return _token;
  }

  Future<void> removeToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('🔑 Token removed');
  }

  // ✅ RESPONSE HANDLERS for ApiResponse<T> format
  Future<T> _handleApiResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    print('📨 Response Status: ${response.statusCode}');
    print('📨 Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204 || response.body.isEmpty) {
        throw Exception('No content returned from server');
      }

      final responseBody = jsonDecode(response.body);

      // ✅ Handle ApiResponse<T> format from backend
      if (responseBody is Map<String, dynamic> &&
          responseBody.containsKey('success')) {
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return fromJson(responseBody['data'] as Map<String, dynamic>);
        } else {
          throw Exception(responseBody['message'] ?? 'API request failed');
        }
      }

      // Fallback for direct response
      return fromJson(responseBody as Map<String, dynamic>);
    } else {
      await _handleError(response);
      throw Exception('Request failed');
    }
  }

  Future<List<T>> _handleApiListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    print('📨 List Response Status: ${response.statusCode}');
    print('📨 List Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseBody = jsonDecode(response.body);

      // ✅ Handle ApiResponse<List<T>> format
      if (responseBody is Map<String, dynamic> &&
          responseBody.containsKey('success')) {
        if (responseBody['success'] == true && responseBody['data'] != null) {
          final List<dynamic> dataList = responseBody['data'] as List<dynamic>;
          return dataList
              .map((json) => fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(responseBody['message'] ?? 'API request failed');
        }
      }

      // Fallback for direct array response
      final List<dynamic> jsonList = responseBody as List<dynamic>;
      return jsonList
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      await _handleError(response);
      throw Exception('Request failed');
    }
  }

  Future<void> _handleVoidApiResponse(http.Response response) async {
    print('📨 Void Response Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody is Map<String, dynamic> &&
              responseBody.containsKey('success')) {
            if (responseBody['success'] != true) {
              throw Exception(responseBody['message'] ?? 'API request failed');
            }
          }
        } catch (e) {
          print('🔧 JSON parse ignored for void response: $e');
        }
      }
      return; // Success
    } else {
      await _handleError(response);
    }
  }

  Future<Map<String, dynamic>> _handleRawApiResponse(
      http.Response response) async {
    print('📨 Raw Response Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseBody = jsonDecode(response.body);

      // ✅ Handle ApiResponse<Object> format
      if (responseBody is Map<String, dynamic> &&
          responseBody.containsKey('success')) {
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return responseBody['data'] as Map<String, dynamic>;
        } else {
          throw Exception(responseBody['message'] ?? 'API request failed');
        }
      }

      return responseBody as Map<String, dynamic>;
    } else {
      await _handleError(response);
      throw Exception('Request failed');
    }
  }

  // ✅ ERROR HANDLER với backend error format
  Future<void> _handleError(http.Response response) async {
    print(
        '❌ HTTP Error - Status: ${response.statusCode}, Body: ${response.body}');

    try {
      if (response.body.isEmpty) {
        switch (response.statusCode) {
          case 404:
            throw Exception('API endpoint not found (404)');
          case 500:
            throw Exception('Server error (500)');
          default:
            throw Exception('HTTP ${response.statusCode}: Empty response');
        }
      }

      final errorBody = jsonDecode(response.body);
      String message = 'Unknown error occurred';
      String errorCode = 'UNKNOWN_ERROR';

      if (errorBody is Map<String, dynamic>) {
        if (errorBody.containsKey('success') && errorBody['success'] == false) {
          message = errorBody['message'] ?? message;
        } else if (errorBody.containsKey('errorCode')) {
          message = errorBody['message'] ?? message;
          errorCode = errorBody['errorCode'] ?? errorCode;
        } else {
          message = errorBody['message'] ?? errorBody.toString();
        }
      }

      // ✅ Handle specific backend error codes
      switch (errorCode) {
        case 'EMAIL_ALREADY_EXISTS':
          throw Exception('Email đã được sử dụng');
        case 'INVALID_CREDENTIALS':
          throw Exception('Email hoặc mật khẩu không đúng');
        case 'VALIDATION_ERROR':
          throw Exception('Dữ liệu không hợp lệ: $message');
        case 'UNAUTHORIZED':
          await removeToken();
          throw Exception('Phiên đăng nhập đã hết hạn');
        default:
          switch (response.statusCode) {
            case 400:
              throw Exception('Bad Request: $message');
            case 401:
              await removeToken();
              throw Exception('Unauthorized: $message');
            case 403:
              throw Exception('Forbidden: $message');
            case 404:
              throw Exception('Not Found: $message');
            case 409:
              throw Exception('Conflict: $message');
            case 500:
              throw Exception('Server Error: $message');
            default:
              throw Exception('HTTP ${response.statusCode}: $message');
          }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // ===================================
  // AUTH APIs - Updated cho backend
  // ===================================

  Future<AuthResponse> login(String email, String password) async {
    try {
      print('🚀 Login request to: $baseUrl/api/auth/login');

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      final authResponse = await _handleApiResponse(
          response, (json) => AuthResponse.fromJson(json));
      await saveToken(authResponse.token);
      return authResponse;
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<AuthResponse> register(
      String name, String email, String password) async {
    try {
      print('🚀 Register request to: $baseUrl/api/auth/register');

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name, // ✅ Updated field name
          'email': email,
          'password': password,
        }),
      );

      final authResponse = await _handleApiResponse(
          response, (json) => AuthResponse.fromJson(json));
      await saveToken(authResponse.token);
      return authResponse;
    } catch (e) {
      print('❌ Register error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      print('🚀 Get current user from: $baseUrl/api/auth/me');

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: _headers,
      );

      return await _handleApiResponse(response, (json) => User.fromJson(json));
    } catch (e) {
      print('❌ Get current user error: $e');
      throw Exception('Get current user failed: ${e.toString()}');
    }
  }

  // ✅ REFRESH TOKEN - API có endpoint này
  Future<AuthResponse> refreshToken() async {
    try {
      print('🚀 Refresh token from: $baseUrl/api/auth/refresh');

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: _headers,
        body: jsonEncode({}),
      );

      final authResponse = await _handleApiResponse(
          response, (json) => AuthResponse.fromJson(json));
      await saveToken(authResponse.token);
      return authResponse;
    } catch (e) {
      print('❌ Refresh token error: $e');
      await removeToken();
      throw Exception('Token refresh failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      print('🚪 Logging out...');
      // API không có logout endpoint, chỉ clear token
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await removeToken();
    }
  }

  // ✅ CHANGE PASSWORD - Updated với backend endpoint
  Future<void> changePassword(String currentPassword, String newPassword,
      String confirmNewPassword) async {
    try {
      print('🚀 Change password request to: $baseUrl/api/auth/change-password');

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/change-password'),
        headers: _headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword, // ✅ Updated field name
        }),
      );

      await _handleVoidApiResponse(response);
      print('✅ Password changed successfully');
    } catch (e) {
      print('❌ Change password error: $e');
      throw Exception('Change password failed: ${e.toString()}');
    }
  }

  // ✅ GENERATE RANDOM PASSWORD - API có endpoint này
  Future<Map<String, dynamic>> generateRandomPassword(int length) async {
    try {
      print(
          '🚀 Generate password request to: $baseUrl/api/auth/generate-password?length=$length');

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/generate-password?length=$length'),
        headers: _headers,
        body: jsonEncode({}),
      );

      return await _handleRawApiResponse(response);
    } catch (e) {
      print('❌ Generate password error: $e');
      throw Exception('Generate password failed: ${e.toString()}');
    }
  }

  // ===================================
  // TODO APIs - Updated với backend endpoints
  // ===================================

  Future<List<TodoItem>> getAllTodoItems() async {
    try {
      print('🚀 Get all todos from: $baseUrl/api/todoitems');

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/todoitems'),
        headers: _headers,
      );

      return await _handleApiListResponse(
          response, (json) => TodoItem.fromJson(json));
    } catch (e) {
      print('❌ Get todos error: $e');
      throw Exception('Get todo items failed: ${e.toString()}');
    }
  }

  Future<List<TodoItem>> getCompletedTodoItems() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/todoitems/completed'),
        headers: _headers,
      );

      return await _handleApiListResponse(
          response, (json) => TodoItem.fromJson(json));
    } catch (e) {
      throw Exception('Get completed todo items failed: ${e.toString()}');
    }
  }

  Future<List<TodoItem>> getPendingTodoItems() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/todoitems/pending'),
        headers: _headers,
      );

      return await _handleApiListResponse(
          response, (json) => TodoItem.fromJson(json));
    } catch (e) {
      throw Exception('Get pending todo items failed: ${e.toString()}');
    }
  }

  Future<List<TodoItem>> getOverdueTodoItems() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/todoitems/overdue'),
        headers: _headers,
      );

      return await _handleApiListResponse(
          response, (json) => TodoItem.fromJson(json));
    } catch (e) {
      throw Exception('Get overdue todo items failed: ${e.toString()}');
    }
  }

  Future<TodoItem> getTodoItem(int id) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/todoitems/$id'),
        headers: _headers,
      );

      return await _handleApiResponse(
          response, (json) => TodoItem.fromJson(json));
    } catch (e) {
      throw Exception('Get todo item failed: ${e.toString()}');
    }
  }

  // ✅ CREATE TODO ITEM - Updated với backend structure
  Future<TodoItem> createTodoItem(
      String title, String? description, DateTime? dueDate) async {
    try {
      print('🚀 Create todo item: $title');

      final requestBody = {
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (dueDate != null)
          'dueDate':
              DateTimeUtils.formatForApi(dueDate), // ✅ Using DateTimeUtils
      };

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/todoitems'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      return await _handleApiResponse(
          response, (json) => TodoItem.fromJson(json));
    } catch (e) {
      print('❌ Create todo error: $e');
      throw Exception('Create todo item failed: ${e.toString()}');
    }
  }

  // ✅ UPDATE TODO ITEM - Updated với backend structure
  Future<void> updateTodoItem(int id, String title, String? description,
      bool isCompleted, DateTime? dueDate) async {
    try {
      print('🚀 Update todo item $id');

      final requestBody = {
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        if (dueDate != null)
          'dueDate':
              DateTimeUtils.formatForApi(dueDate), // ✅ Using DateTimeUtils
      };

      final response = await _httpClient.put(
        Uri.parse('$baseUrl/api/todoitems/$id'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      _handleVoidApiResponse(response);
      print('✅ Todo updated successfully');
    } catch (e) {
      print('❌ Update todo error: $e');
      throw Exception('Update todo item failed: ${e.toString()}');
    }
  }

  Future<void> deleteTodoItem(int id) async {
    try {
      print('🚀 Delete todo item $id');

      final response = await _httpClient.delete(
        Uri.parse('$baseUrl/api/todoitems/$id'),
        headers: _headers,
      );

      _handleVoidApiResponse(response);
      print('✅ Todo deleted successfully');
    } catch (e) {
      print('❌ Delete todo error: $e');
      throw Exception('Delete todo item failed: ${e.toString()}');
    }
  }

  // ✅ TOGGLE TODO - API có endpoint riêng
  Future<void> toggleTodoItem(int id) async {
    try {
      print('🚀 Toggle todo item $id');

      final response = await _httpClient.patch(
        Uri.parse('$baseUrl/api/todoitems/$id/toggle'),
        headers: _headers,
      );

      _handleVoidApiResponse(response);
      print('✅ Todo toggled successfully');
    } catch (e) {
      print('❌ Toggle todo error: $e');
      throw Exception('Toggle todo item failed: ${e.toString()}');
    }
  }

  // ✅ GET TODO STATS - Updated với TodoStats structure
  Future<TodoStats> getTodoStats() async {
    try {
      print('🚀 Get todo stats from: $baseUrl/api/todoitems/stats');

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/todoitems/stats'),
        headers: _headers,
      );

      final statsData = await _handleRawApiResponse(response);
      return TodoStats.fromJson(statsData);
    } catch (e) {
      print('❌ Get stats error: $e');
      throw Exception('Get todo stats failed: ${e.toString()}');
    }
  }

  // ===================================
  // UTILITY METHODS
  // ===================================

  Future<bool> checkApiHealth() async {
    try {
      print('🔍 Testing API health: $baseUrl/health');

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('✅ Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ API health check failed: $e');
      return false;
    }
  }

  Future<void> debugConnection() async {
    try {
      print('🔧 DEBUG: Testing connection to $baseUrl');

      final healthResponse = await _httpClient.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('🔧 DEBUG Health: ${healthResponse.statusCode}');

      final infoResponse = await _httpClient.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print('🔧 DEBUG Info: ${infoResponse.statusCode}');
    } catch (e) {
      print('🔧 DEBUG Connection failed: $e');
      print('🔧 Make sure your .NET API is running on https://localhost:7215');
    }
  }

  // ✅ UPDATE PROFILE - Sử dụng Users API
  Future<void> updateProfile(int userId, String name, String email) async {
    try {
      print('🚀 Update profile for user $userId');

      final requestBody = {
        'id': userId,
        'name': name.trim(),
        'email': email.trim(),
      };

      final response = await _httpClient.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      await _handleVoidApiResponse(response);
      print('✅ Profile updated successfully');
    } catch (e) {
      print('❌ Update profile error: $e');
      throw Exception('Update profile failed: ${e.toString()}');
    }
  }

  // ✅ GET USER BY ID - Để lấy thông tin updated
  Future<User> getUserById(int userId) async {
    try {
      print('🚀 Get user by ID: $userId');

      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _headers,
      );

      return await _handleApiResponse(response, (json) => User.fromJson(json));
    } catch (e) {
      print('❌ Get user by ID error: $e');
      throw Exception('Get user failed: ${e.toString()}');
    }
  }
}

// ✅ AUTH RESPONSE updated cho backend format
class AuthResponse {
  final String token;
  final User user;
  final DateTime expires; // ✅ Added expires field

  AuthResponse({
    required this.token,
    required this.user,
    required this.expires,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      expires: DateTimeUtils.parseFromApi(json['expires']) ??
          DateTime.now().add(const Duration(days: 7)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'expires': DateTimeUtils.formatForApi(expires),
    };
  }
}

// ✅ TODO STATS updated cho backend format
class TodoStats {
  final int totalCount;
  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  final double completionRate;

  TodoStats({
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.completionRate,
  });

  factory TodoStats.fromJson(Map<String, dynamic> json) {
    return TodoStats(
      totalCount: json['totalCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
      overdueCount: json['overdueCount'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'overdueCount': overdueCount,
      'completionRate': completionRate,
    };
  }

  // ✅ Computed properties
  double get completionPercentage => completionRate;
  bool get hasOverdueTodos => overdueCount > 0;
  bool get hasCompletedTodos => completedCount > 0;
  bool get isEmpty => totalCount == 0;
}

// ✅ SSL BYPASS cho development
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final isLocalhost =
            host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';

        if (isLocalhost) {
          print('🔐 SSL Bypass for development host: $host:$port');
          return true;
        }

        return false;
      };
  }
}
