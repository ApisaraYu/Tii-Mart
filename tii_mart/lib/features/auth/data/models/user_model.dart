import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

/// แปลงข้อมูลจาก Firestore เป็น AppUser (เอกสาร users/{uid})
class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.phone,
    required super.username,
    required super.role,
    super.shopId,
    super.photoUrl,
    super.createdAt,
  });

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return UserModel(
      uid: doc.id,
      email: (data['email'] ?? '') as String,
      firstName: (data['firstName'] ?? '') as String,
      lastName: (data['lastName'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      username: (data['username'] ?? '') as String,
      role: UserRole.fromString(data['role'] as String?),
      shopId: data['shopId'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
