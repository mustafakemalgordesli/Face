import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/user/UserDataManager.dart';
import '../services/user/user_data.dart';
import 'registration_screen.dart';
import 'home_screen.dart';
import '../services/token_manager.dart';
import '../services/ip_adress.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isResident = true; // Default to 'Sakin'

  get ip_adres => ipAdres;

  void _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    String url = "$ip_adres/user/login";
    var data = {
      "email": username,
      "password": password
    };

    var response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      var loginResponse = json.decode(response.body);
      print("Login Response: $loginResponse");

      // Check if login was successful
      if (loginResponse['token'] != null) {
        TokenManager().setToken(loginResponse['token']);
        print(loginResponse['token']);

        UserData userData = UserData.fromJson(loginResponse['user']);
        UserDataManager.setUserData(userData);

        if (_isResident) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          // Navigate to the guest screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreenGuest()), // Replace with actual guest screen
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcı adı veya şifre hatalı')),
        );
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş yapılamadı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apsiyon Hackton'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/icons/app_icon.png'),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sakin'),
                    Switch(
                      value: !_isResident,
                      onChanged: (value) {
                        setState(() {
                          _isResident = !value;
                        });
                      },
                    ),
                    Text('Misafir'),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Giriş'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => RegistrationScreen(),
                    );
                  },
                  child: Text('Kayıt Ol'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
