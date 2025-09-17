// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  String? get userToken => _apiService.token;

  // ✅ INITIALIZE - Updated for new API structure
  Future<void> initialize() async {
    _setLoading(true);
    _setError(null);

    try {
      // ✅ TEST API CONNECTION với health endpoint
      print('🔧 Testing API connection during initialization...');
      await _apiService.checkApiHealth();

      await _apiService.loadToken();

      if (_apiService.hasToken) {
        try {
          await getCurrentUser();
        } catch (e) {
          // Nếu token invalid, logout và clear data
          print('Token invalid during initialization: $e');
          await logout();
        }
      }
    } catch (e) {
      _setError('Initialization failed: ${e.toString()}');
      print('AuthProvider initialization error: $e');
    } finally {
      _isInitialized = true;
      _setLoading(false);
      // Ensure UI is notified about initialization completion
      notifyListeners();
    }
  }

  // ✅ LOGIN - Updated with new API response structure
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      // Validate input
      if (email.trim().isEmpty || password.trim().isEmpty) {
        throw Exception('Email và mật khẩu không được để trống');
      }

      // ✅ API trả về ApiResponse<LoginResponse>
      final authResponse = await _apiService.login(
        email.trim(),
        password,
      );

      _currentUser = authResponse.user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ REGISTER - Updated with password strength validation
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      // Validate input theo requirements của API
      if (name.trim().isEmpty ||
          email.trim().isEmpty ||
          password.trim().isEmpty) {
        throw Exception('Tất cả các trường đều bắt buộc');
      }

      // ✅ API yêu cầu password mạnh (8 ký tự, chữ hoa, chữ thường, số, ký tự đặc biệt)
      if (password.length < 8) {
        throw Exception('Mật khẩu phải có ít nhất 8 ký tự');
      }

      if (!_isPasswordStrong(password)) {
        throw Exception(
            'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt');
      }

      final authResponse = await _apiService.register(
        name.trim(),
        email.trim(),
        password,
      );

      _currentUser = authResponse.user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ GET CURRENT USER - Updated with new API endpoint
  Future<void> getCurrentUser() async {
    if (!_apiService.hasToken) {
      _setError('No authentication token available');
      return;
    }

    try {
      // ✅ API endpoint: GET /api/auth/me
      _currentUser = await _apiService.getCurrentUser();
      _clearError();
      notifyListeners();
    } catch (e) {
      final errorMessage = _parseErrorMessage(e.toString());

      // Nếu là lỗi authentication, logout user
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('401') ||
          e.toString().contains('InvalidTokenException')) {
        print('Authentication error, logging out user: $e');
        await logout();
      } else {
        _setError(errorMessage);
      }
    }
  }

  // ✅ LOGOUT - Simple logout (API không có logout endpoint)
  Future<void> logout() async {
    print('🔓 Bắt đầu logout...');
    _setLoading(true);

    try {
      // Clear token và local storage
      await _apiService.logout();
      print('🔓 API logout thành công');
    } catch (e) {
      print('Error during logout: $e');
      // Continue with logout even if API call fails
    }

    // NOTE: Don't clear remembered credentials on logout - 
    // only clear them when user unchecks "remember me" in login
    // await _clearRememberedCredentials();

    // Clear local state
    _currentUser = null;
    print('🔓 Cleared _currentUser: $_currentUser');
    print('🔓 isAuthenticated after logout: $isAuthenticated');
    _clearError();
    _setLoading(false);
    notifyListeners();
    print('🔓 notifyListeners() called - logout hoàn tất');
  }

  // ✅ CLEAR REMEMBERED CREDENTIALS ON LOGOUT
  Future<void> _clearRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      await prefs.setBool('remember_me', false);
      print('🗑️ Remembered credentials cleared on logout');
    } catch (e) {
      print('❌ Error clearing remembered credentials: $e');
    }
  }

  // ✅ REFRESH TOKEN - API có endpoint refresh
  Future<bool> refreshToken() async {
    if (!_apiService.hasToken) {
      return false;
    }

    try {
      // ✅ API endpoint: POST /api/auth/refresh
      final authResponse = await _apiService.refreshToken();
      _currentUser = authResponse.user;
      notifyListeners();
      return true;
    } catch (e) {
      print('Token refresh failed: $e');
      await logout();
      return false;
    }
  }

  // ✅ REFRESH USER DATA từ server
  Future<void> refreshUserData() async {
    if (!isAuthenticated || _currentUser == null) return;

    try {
      print('🔄 Refreshing user data for user ${_currentUser!.id}');
      
      final updatedUser = await _apiService.getUserById(_currentUser!.id);
      _currentUser = updatedUser;
      notifyListeners();
      
      print('✅ User data refreshed successfully');
    } catch (e) {
      print('❌ Refresh user data error: $e');
      // Don't show error to user for silent refresh
    }
  }

  // ✅ CHECK API CONNECTIVITY
  Future<bool> checkApiConnection() async {
    try {
      return await _apiService.checkApiHealth();
    } catch (e) {
      print('API health check failed: $e');
      return false;
    }
  }

  // ✅ UPDATE PROFILE - Sử dụng API thực sự
  Future<bool> updateProfile(String name, String email) async {
    if (!isAuthenticated || _currentUser == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      print('🚀 Updating profile for user ${_currentUser!.id}');
      
      // ✅ Validation
      if (name.trim().isEmpty) {
        _setError('Tên không được để trống');
        return false;
      }
      
      if (email.trim().isEmpty) {
        _setError('Email không được để trống');
        return false;
      }
      
      if (name.trim().length > 100) {
        _setError('Tên không được vượt quá 100 ký tự');
        return false;
      }
      
      if (email.trim().length > 255) {
        _setError('Email không được vượt quá 255 ký tự');
        return false;
      }

      // ✅ Email format validation
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email.trim())) {
        _setError('Email không đúng định dạng');
        return false;
      }

      // ✅ Call API to update profile
      await _apiService.updateProfile(_currentUser!.id, name.trim(), email.trim());
      
      // ✅ Fetch updated user info from server
      final updatedUser = await _apiService.getUserById(_currentUser!.id);
      
      // ✅ Update local user data
      _currentUser = updatedUser;
      notifyListeners();
      
      print('✅ Profile updated successfully');
      return true;

    } catch (e) {
      print('❌ Update profile error: $e');
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ CHANGE PASSWORD - API có endpoint change-password
  Future<bool> changePassword(String currentPassword, String newPassword,
      String confirmPassword) async {
    if (!isAuthenticated) {
      _setError('User not authenticated');
      return false;
    }

    // Validate password strength theo API requirements
    if (newPassword.length < 8) {
      _setError('Mật khẩu mới phải có ít nhất 8 ký tự');
      return false;
    }

    if (!_isPasswordStrong(newPassword)) {
      _setError(
          'Mật khẩu mới phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt');
      return false;
    }

    if (newPassword != confirmPassword) {
      _setError('Mật khẩu xác nhận không khớp');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // ✅ API endpoint: POST /api/auth/change-password
      // API dùng confirmNewPassword thay vì confirmPassword
      await _apiService.changePassword(
        currentPassword,
        newPassword,
        confirmPassword,
      );

      return true;
    } catch (e) {
      _setError(_parseErrorMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ GENERATE RANDOM PASSWORD - API có endpoint này
  Future<String?> generateRandomPassword({int length = 12}) async {
    if (!isAuthenticated) {
      _setError('User not authenticated');
      return null;
    }

    try {
      // ✅ API endpoint: POST /api/auth/generate-password?length=12
      final response = await _apiService.generateRandomPassword(length);
      return response['password'] as String?;
    } catch (e) {
      print('Generate password failed: $e');
      return null;
    }
  }

  // ================================
  // PRIVATE HELPER METHODS
  // ================================

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // ✅ PASSWORD STRENGTH VALIDATION theo API requirements
  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;

    // Ít nhất 1 chữ hoa
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    // Ít nhất 1 chữ thường
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    // Ít nhất 1 số
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    // Ít nhất 1 ký tự đặc biệt
    bool hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  // ✅ PARSE ERROR MESSAGE - Updated với các lỗi từ API
  String _parseErrorMessage(String error) {
    String cleanError = error.replaceFirst('Exception: ', '');

    print('Original error: $error');
    print('Clean error: $cleanError');

    // Handle API-specific errors
    if (cleanError.contains('EMAIL_ALREADY_EXISTS') ||
        cleanError.contains('Email đã được sử dụng')) {
      return 'Email này đã được đăng ký. Vui lòng sử dụng email khác.';
    } else if (cleanError.contains('INVALID_CREDENTIALS') ||
        cleanError.contains('Email hoặc mật khẩu không đúng')) {
      return 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.';
    } else if (cleanError.contains('VALIDATION_ERROR') ||
        cleanError.contains('Mật khẩu phải có ít nhất 8 ký tự')) {
      return 'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt';
    } else if (cleanError.contains('USER_NOT_FOUND')) {
      return 'Người dùng không tồn tại. Vui lòng đăng ký tài khoản mới.';
    } else if (cleanError.contains('INVALID_TOKEN') ||
        cleanError.contains('InvalidTokenException')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    } else if (cleanError.contains('CONNECTION_REFUSED') ||
        cleanError.contains('SocketException')) {
      return 'Không thể kết nối đến server. Vui lòng kiểm tra:\n• Server có đang chạy tại https://localhost:7215 không?\n• Kết nối mạng có ổn định không?';
    } else if (cleanError.contains('CERTIFICATE_ERROR') ||
        cleanError.contains('TlsException')) {
      return 'Lỗi bảo mật SSL. Vui lòng kiểm tra cấu hình HTTPS của server.';
    } else if (cleanError.contains('TIMEOUT')) {
      return 'Kết nối quá chậm. Vui lòng thử lại.';
    } else if (cleanError.contains('500') ||
        cleanError.contains('INTERNAL_SERVER_ERROR')) {
      return 'Lỗi máy chủ. Vui lòng thử lại sau.';
    } else if (cleanError.contains('400') ||
        cleanError.contains('BAD_REQUEST')) {
      return 'Dữ liệu gửi lên không hợp lệ. Vui lòng kiểm tra lại.';
    } else if (cleanError.contains('401') ||
        cleanError.contains('UNAUTHORIZED')) {
      return 'Không có quyền truy cập. Vui lòng đăng nhập lại.';
    } else if (cleanError.contains('403') || cleanError.contains('FORBIDDEN')) {
      return 'Bạn không có quyền thực hiện hành động này.';
    } else if (cleanError.contains('404') || cleanError.contains('NOT_FOUND')) {
      return 'Không tìm thấy dữ liệu yêu cầu.';
    }

    // Return original message if no pattern matches
    return cleanError.isEmpty ? 'Đã xảy ra lỗi không xác định' : cleanError;
  }

  // ✅ RESET STATE
  void resetState() {
    _currentUser = null;
    _isLoading = false;
    _error = null;
    _isInitialized = false;
    notifyListeners();
  }

  // ✅ GET USER DISPLAY NAME
  String get userDisplayName {
    if (_currentUser != null) {
      return _currentUser!.name.isNotEmpty
          ? _currentUser!.name
          : _currentUser!.email;
    }
    return 'Guest';
  }

  // ✅ GET USER INITIALS for avatar
  String get userInitials {
    if (_currentUser != null && _currentUser!.name.isNotEmpty) {
      List<String> nameParts = _currentUser!.name.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        return nameParts[0][0].toUpperCase();
      }
    }
    return 'U';
  }

  // ✅ GET USER EMAIL DOMAIN for display
  String get userEmailDomain {
    if (_currentUser != null && _currentUser!.email.contains('@')) {
      return _currentUser!.email.split('@')[1];
    }
    return '';
  }

  // ✅ CHECK IF USER IS NEW (registered recently)
  bool get isNewUser {
    if (_currentUser != null) {
      final now = DateTime.now();
      final difference = now.difference(_currentUser!.createdAt);
      return difference.inDays <= 7; // Consider new if registered within 7 days
    }
    return false;
  }
}
