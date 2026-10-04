enum UserRole {
  customer,
  seller;

  static UserRole fromString(String? value) {
    return value == 'seller' ? UserRole.seller : UserRole.customer;
  }

  String get label => this == UserRole.seller ? 'เจ้าของร้านค้า' : 'ลูกค้า';
}

/// ข้อมูลผู้ใช้ตามความหมายทางธุรกิจ (ไม่ผูกกับ Firebase)
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.username,
    required this.role,
    this.shopId,
    this.photoUrl,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String username;
  final UserRole role;
  final String? shopId;
  final String? photoUrl;
  final DateTime? createdAt;

  bool get isSeller => role == UserRole.seller;
  String get fullName => '$firstName $lastName'.trim();
}
