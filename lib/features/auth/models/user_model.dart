import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? activeMessId;
  
  // Smart Member & ICE Features
  final String? phone;
  final String? presentAddress;
  final String? permanentAddress;
  final String? iceName;
  final String? icePhone;
  final String? bloodGroup;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.activeMessId,
    this.phone,
    this.presentAddress,
    this.permanentAddress,
    this.iceName,
    this.icePhone,
    this.bloodGroup,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt), // Always save as Timestamp
      'activeMessId': activeMessId,
      'phone': phone,
      'presentAddress': presentAddress,
      'permanentAddress': permanentAddress,
      'iceName': iceName,
      'icePhone': icePhone,
      'bloodGroup': bloodGroup,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // CRITICAL FIX: Indestructible Date Parsing
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      } else if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      }
    }

    return UserModel(
      // Safely convert everything to string to prevent 'Null is not a subtype' crashes
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown User',
      email: map['email']?.toString() ?? '',
      createdAt: parsedDate,
      activeMessId: map['activeMessId']?.toString(),
      phone: map['phone']?.toString(),
      presentAddress: map['presentAddress']?.toString(),
      permanentAddress: map['permanentAddress']?.toString(),
      iceName: map['iceName']?.toString(),
      icePhone: map['icePhone']?.toString(),
      bloodGroup: map['bloodGroup']?.toString(),
    );
  }
}
