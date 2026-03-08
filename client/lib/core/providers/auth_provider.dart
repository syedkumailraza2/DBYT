import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  String? _userId;
  String? _username;
  String? _errorMessage;
  UserData? _user;

  AuthProvider(this._authService);

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get username => _username;
  String? get errorMessage => _errorMessage;
  UserData? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuthStatus() async {
    print('[AUTH_PROVIDER] checkAuthStatus started');
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final authData = await _authService.getStoredAuthData();

      if (authData != null) {
        print('[AUTH_PROVIDER] Found stored auth data');
        _userId = authData.userId;
        _username = authData.username;

        // Verify token is still valid by fetching user
        print('[AUTH_PROVIDER] Verifying token by fetching user...');
        final userData = await _authService.getCurrentUser();
        if (userData != null) {
          print('[AUTH_PROVIDER] Token valid, user authenticated');
          _user = userData;
          _status = AuthStatus.authenticated;
        } else {
          // Token is invalid, clear it
          print('[AUTH_PROVIDER] Token invalid, logging out');
          await _authService.logout();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        print('[AUTH_PROVIDER] No stored auth data, unauthenticated');
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('[AUTH_PROVIDER] checkAuthStatus error: $e');
      _status = AuthStatus.unauthenticated;
    }

    print('[AUTH_PROVIDER] checkAuthStatus complete, status: $_status');
    notifyListeners();
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    print('[AUTH_PROVIDER] register started - username: $username, email: $email');
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      username: username,
      email: email,
      password: password,
    );

    if (result.success) {
      print('[AUTH_PROVIDER] register successful');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    }

    print('[AUTH_PROVIDER] register failed: ${result.message}');
    _status = AuthStatus.error;
    _errorMessage = result.message;
    notifyListeners();
    return false;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    print('[AUTH_PROVIDER] login started - email: $email');
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(
      email: email,
      password: password,
    );

    if (result.success) {
      print('[AUTH_PROVIDER] login successful - userId: ${result.userId}, username: ${result.username}');
      _userId = result.userId;
      _username = result.username;
      _status = AuthStatus.authenticated;

      // Fetch full user data
      print('[AUTH_PROVIDER] Fetching full user data...');
      final userData = await _authService.getCurrentUser();
      if (userData != null) {
        print('[AUTH_PROVIDER] User data fetched successfully');
        _user = userData;
      }

      notifyListeners();
      return true;
    }

    print('[AUTH_PROVIDER] login failed: ${result.message}');
    _status = AuthStatus.error;
    _errorMessage = result.message;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    print('[AUTH_PROVIDER] logout started');
    await _authService.logout();
    _userId = null;
    _username = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    print('[AUTH_PROVIDER] logout complete');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? username,
    String? email,
    String? password,
  }) async {
    print('[AUTH_PROVIDER] updateProfile started');
    _errorMessage = null;

    final result = await _authService.updateProfile(
      username: username,
      email: email,
      password: password,
    );

    if (result.success && result.user != null) {
      print('[AUTH_PROVIDER] Profile updated successfully');
      _user = result.user;
      _username = result.user!.username;
      notifyListeners();
      return true;
    }

    print('[AUTH_PROVIDER] Profile update failed: ${result.message}');
    _errorMessage = result.message;
    notifyListeners();
    return false;
  }

  Future<void> refreshUser() async {
    print('[AUTH_PROVIDER] Refreshing user data...');
    final userData = await _authService.getCurrentUser();
    if (userData != null) {
      _user = userData;
      _username = userData.username;
      notifyListeners();
    }
  }
}

// Factory function to create AuthProvider with dependencies
AuthProvider createAuthProvider() {
  final apiService = ApiService();
  final authService = AuthService(apiService);
  return AuthProvider(authService);
}
