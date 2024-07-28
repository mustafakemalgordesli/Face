class UserData {
  int id_data;
  String fullname_data;
  String email_data;
  String? imageUrl_data; // Make this field nullable

  UserData({required this.id_data, required this.fullname_data, required this.email_data, this.imageUrl_data});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id_data: json['id'],
      fullname_data: json['fullname'],
      email_data: json['email'],
      imageUrl_data: json['imageurl'], // This can now be null
    );
  }
  void updateImageUrl(String newUrl) {
    imageUrl_data = newUrl;
  }
}
