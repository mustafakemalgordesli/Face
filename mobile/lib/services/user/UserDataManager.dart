import 'user_data.dart';

class UserDataManager {
  static UserData? _userData;

  static void setUserData(UserData userData) {
    _userData = userData;
  }

  static UserData? getUserData() {
    return _userData;
  }

  static void clearUserData() {
    _userData = null;
  }
}
