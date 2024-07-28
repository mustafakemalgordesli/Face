// user_info_screen.dart
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mobil_app/screens/home_screen.dart';
import 'package:path/path.dart' as path;
import '../services/token_manager.dart';
import '../services/ip_adress.dart';
import '../services/user/UserDataManager.dart';
import '../services/user/user_data.dart';

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  
  get ip_adres => ipAdres;
  UserData? userData = UserDataManager.getUserData();
  get imageurl => userData?.imageUrl_data;

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _choosePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updatePhoto() async {
    if (_image == null) return;

    final url = Uri.parse("$ip_adres/user/photo");
    final token = await TokenManager().getToken();
    if (token == null) {
      print("Token is not available");
      return;
    }

    final headers = {
      "Authorization": token,
    };

    print("Sending request with token: $token");
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..files.add(await http.MultipartFile.fromPath('image', _image!.path,
          filename: path.basename(_image!.path)));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        print("Update Photo Response: ${responseData.body}");
        final newImageUrl = jsonDecode(responseData.body)['imageurl'];
        // Update the image URL in userData and refresh the UI
        setState(() {
          userData?.updateImageUrl(newImageUrl);
        });

        // Navigate back to HomeScreen and refresh
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()), // Navigate to HomeScreen
        );
        
         // Kayıt başarılı toast gösterimi
        Fluttertoast.showToast(
          msg: "Kayıt başarılı",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        final responseData = await http.Response.fromStream(response);
        print("Failed to upload photo: ${responseData.statusCode}");
        print("Response: ${responseData.body}");
      }
    } catch (e) {
      print("Exception caught: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Text(
              'Kullanıcı Bilgilerini Güncelleme',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            _image == null
                ? Text('Fotoğraf seçili değil!')
                : Image.file(_image!, height: 200),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: Text('Fotoğraf çekin'),
                  selected: false,
                  onSelected: (selected) {
                    _takePhoto();
                  },
                ),
                ChoiceChip(
                  label: Text('Galeriye bakın'),
                  selected: false,
                  onSelected: (selected) {
                    _choosePhoto();
                  },
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _updatePhoto,
              child: Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}