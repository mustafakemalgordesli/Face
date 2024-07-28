import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main_screen.dart';
import 'user_info_screen.dart';
import 'create_permission_screen.dart';
import 'entry_exit_info_screen.dart';
import '../services/user/UserDataManager.dart';
import '../services/user/user_data.dart';
import '../services/ip_adress.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _profileImageUrl = '';
  String _userName = '';
  String _userEmail = '';

  UserData? userData = UserDataManager.getUserData();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    if (userData != null) {
      setState(() {
        _profileImageUrl = ipAdres + (userData?.imageUrl_data ?? '');
        _userName = userData?.fullname_data ?? '';
        _userEmail = userData?.email_data ?? '';
      });
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _profileImageUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 100,
                      backgroundImage: NetworkImage(_profileImageUrl),
                    )
                  : CircularProgressIndicator(),
              SizedBox(height: 10),
              Text(
                _userName, 
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _userEmail,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => UserInfoScreen(),
                  );
                },
                child: Text('Bilgileri Güncelle'),
              ),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => CreatePermissionScreen(),
                  );
                },
                child: Text('Giriş İzni Oluştur'),
              ),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => EntryExitInfoScreen(),
                  );
                },
                child: Text('Giriş-Çıkış Bilgileri'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Misafir anasayfa
class HomeScreenGuest extends StatefulWidget {
  @override
  _HomeScreenGuestState createState() => _HomeScreenGuestState();
}

class _HomeScreenGuestState extends State<HomeScreenGuest> {
  String _profileImageUrl = '';
  String _userName = '';
  String _userEmail = '';

  UserData? userData = UserDataManager.getUserData();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    if (userData != null) {
      setState(() {
        _profileImageUrl = ipAdres + (userData?.imageUrl_data ?? '');
        _userName = userData?.fullname_data ?? '';
        _userEmail = userData?.email_data ?? '';
      });
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Anasayfa Misafir'),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _profileImageUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_profileImageUrl),
                    )
                  : CircularProgressIndicator(),
              SizedBox(height: 10),
              Text(
                _userName, 
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _userEmail,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => UserInfoScreen(),
                  );
                },
                child: Text('Bilgileri Güncelle'),
              ),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => EntryExitInfoScreen(),
                  );
                },
                child: Text('Giriş-Çıkış Bilgileri'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
