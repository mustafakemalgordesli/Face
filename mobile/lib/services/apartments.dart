import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'token_manager.dart';
import 'ip_adress.dart';

Future<List<Map<String, dynamic>>> fetchApartments() async {
  String? token = await TokenManager().getToken();

  if (token == null) {
    Fluttertoast.showToast(
      msg: "Token alınamadı",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    return [];
  }

  final response = await http.get(
    Uri.parse('$ipAdres/apartments'),
    headers: {
      'Authorization': token,
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((apartment) => {
      'apartment_id': apartment['id'],   // Updated key to match your response
      'apartment_name': apartment['name'], // Assuming 'name' is the key for apartment names in your response
    }).toList();
  } else {
    Fluttertoast.showToast(
      msg: "Failed to fetch apartments",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    return [];
  }
}
