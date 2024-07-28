// services/user_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_manager.dart';
import 'ip_adress.dart';

class UserService {
  static get ip_adres => ipAdres;
  
  static Future<String?> fetchUserPhotoUrl() async {
    final url = Uri.parse("$ip_adres/user/photo");
    final token = await TokenManager().getToken();
    if (token == null) {
      print("Token is not available");
      return null;
    }

    final headers = {
      "Authorization": token,
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['photoUrl'];
    } else {
      print("Failed to fetch photo URL: ${response.statusCode}");
      return null;
    }
  }
}
