import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';

  AuthService(this._apiService);

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    print('[AUTH_SERVICE] Register started');
    print('[AUTH_SERVICE] Username: $username, Email: $email');

    final response = await _apiService.post('/user/register', {
      'username': username,
      'email': email,
      'password': password,
    });

    print('[AUTH_SERVICE] Register response - success: ${response.success}, status: ${response.statusCode}');

    if (response.success) {
      print('[AUTH_SERVICE] Register successful, userId: ${response.data?['userId']}');
      return AuthResult(
        success: true,
        message: response.message ?? 'Registration successful',
        userId: response.data?['userId'] as String?,
      );
    }

    print('[AUTH_SERVICE] Register failed: ${response.message}');
    return AuthResult(
      success: false,
      message: response.message ?? 'Registration failed',
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    print('[AUTH_SERVICE] Login started');
    print('[AUTH_SERVICE] Email: $email');

    final response = await _apiService.post('/user/login', {
      'email': email,
      'password': password,
    });

    print('[AUTH_SERVICE] Login response - success: ${response.success}, status: ${response.statusCode}');

    if (response.success && response.data != null) {
      final token = response.data!['token'] as String?;
      final userId = response.data!['userId'] as String?;
      final username = response.data!['username'] as String?;

      print('[AUTH_SERVICE] Login successful - userId: $userId, username: $username');
      print('[AUTH_SERVICE] Token received: ${token != null ? "${token.substring(0, 20)}..." : "null"}');

      if (token != null) {
        print('[AUTH_SERVICE] Saving auth data...');
        await _saveAuthData(token, userId, username);
        _apiService.setToken(token);
        print('[AUTH_SERVICE] Auth data saved');
      }

      return AuthResult(
        success: true,
        message: response.message ?? 'Login successful',
        token: token,
        userId: userId,
        username: username,
      );
    }

    print('[AUTH_SERVICE] Login failed: ${response.message}');
    return AuthResult(
      success: false,
      message: response.message ?? 'Login failed',
    );
  }

  Future<void> _saveAuthData(String token, String? userId, String? username) async {
    try {
      print('[AUTH_SERVICE] Saving to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      print('[AUTH_SERVICE] Got SharedPreferences instance');
      await prefs.setString(_tokenKey, token);
      print('[AUTH_SERVICE] Saved token');
      if (userId != null) await prefs.setString(_userIdKey, userId);
      print('[AUTH_SERVICE] Saved userId');
      if (username != null) await prefs.setString(_usernameKey, username);
      print('[AUTH_SERVICE] Saved username');
      print('[AUTH_SERVICE] SharedPreferences saved successfully');
    } catch (e) {
      print('[AUTH_SERVICE] ERROR saving to SharedPreferences: $e');
    }
  }

  Future<AuthData?> getStoredAuthData() async {
    print('[AUTH_SERVICE] Getting stored auth data...');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null) {
      print('[AUTH_SERVICE] No stored token found');
      return null;
    }

    print('[AUTH_SERVICE] Found stored token: ${token.substring(0, 20)}...');
    _apiService.setToken(token);

    final authData = AuthData(
      token: token,
      userId: prefs.getString(_userIdKey),
      username: prefs.getString(_usernameKey),
    );
    print('[AUTH_SERVICE] Restored auth data - userId: ${authData.userId}, username: ${authData.username}');
    return authData;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getString(_tokenKey) != null;
    print('[AUTH_SERVICE] isLoggedIn: $loggedIn');
    return loggedIn;
  }

  Future<void> logout() async {
    print('[AUTH_SERVICE] Logging out...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    _apiService.setToken(null);
    print('[AUTH_SERVICE] Logged out, data cleared');
  }

  Future<UserData?> getCurrentUser() async {
    print('[AUTH_SERVICE] Getting current user...');
    final response = await _apiService.get('/user/me');

    print('[AUTH_SERVICE] getCurrentUser response - success: ${response.success}, status: ${response.statusCode}');

    if (response.success && response.data != null) {
      final user = response.data!['user'] as Map<String, dynamic>?;
      if (user != null) {
        print('[AUTH_SERVICE] User data received: ${user['username']}');
        return UserData.fromJson(user);
      }
    }

    print('[AUTH_SERVICE] Failed to get current user');
    return null;
  }

  Future<UpdateResult> updateProfile({
    String? username,
    String? email,
    String? password,
  }) async {
    print('[AUTH_SERVICE] Updating profile...');

    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;

    final response = await _apiService.put('/user/me', body);

    print('[AUTH_SERVICE] updateProfile response - success: ${response.success}, status: ${response.statusCode}');

    if (response.success && response.data != null) {
      final user = response.data!['user'] as Map<String, dynamic>?;
      if (user != null) {
        // Update stored username if changed
        if (username != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_usernameKey, username);
        }
        print('[AUTH_SERVICE] Profile updated successfully');
        return UpdateResult(
          success: true,
          message: response.message ?? 'Profile updated',
          user: UserData.fromJson(user),
        );
      }
    }

    print('[AUTH_SERVICE] Profile update failed: ${response.message}');
    return UpdateResult(
      success: false,
      message: response.message ?? 'Update failed',
    );
  }
}

class UpdateResult {
  final bool success;
  final String message;
  final UserData? user;

  UpdateResult({
    required this.success,
    required this.message,
    this.user,
  });
}

class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final String? userId;
  final String? username;

  AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.userId,
    this.username,
  });
}

class AuthData {
  final String token;
  final String? userId;
  final String? username;

  AuthData({
    required this.token,
    this.userId,
    this.username,
  });
}

class UserData {
  final String id;
  final String username;
  final String email;
  final List<String> territories;
  final StreakData? streak;

  UserData({
    required this.id,
    required this.username,
    required this.email,
    required this.territories,
    this.streak,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      territories: (json['territories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      streak: json['streak'] != null
          ? StreakData.fromJson(json['streak'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StreakData {
  final int current;
  final int longest;
  final DateTime? lastActive;

  StreakData({
    required this.current,
    required this.longest,
    this.lastActive,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      current: json['current'] as int? ?? 0,
      longest: json['longest'] as int? ?? 0,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
    );
  }
}
