// token_manager.dart
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  String? _token;

  factory TokenManager() {
    return _instance;
  }

  TokenManager._internal();

  void setToken(String token) {
    _token = token;
    print("Token set: $token");
  }

  Future<String?> getToken() async {
    print("Token retrieved: $_token");
    return _token;
  }

  void clearToken() {
    _token = null;
    print("Token cleared");
  }
}