import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ip_adress.dart';
import 'token_manager.dart';

Future<List<Permission>> fetchPermissions() async {
  String? token = await TokenManager().getToken();

  if (token == null) {
    throw Exception('Token is null');
  }

  final response = await http.get(
    Uri.parse('$ipAdres/permission'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': token,
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Permission.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load permissions');
  }
}

class Permission {
  final int assignedById;
  final int userId;
  final String startDate;
  final String endDate;
  final String qrImageUrl;
  final int id;
  final int apartmentId;

  Permission({
    required this.assignedById,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.qrImageUrl,
    required this.id,
    required this.apartmentId,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      assignedById: json['assigned_by_id'],
      userId: json['user_id'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      qrImageUrl: json['qr_image_url'],
      id: json['id'],
      apartmentId: json['apartment_id'],
    );
  }
}
