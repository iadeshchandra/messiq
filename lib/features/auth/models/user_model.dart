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
      'createdAt': createdAt.toIso8601String(),
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
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      activeMessId: map['activeMessId'],
      phone: map['phone'],
      presentAddress: map['presentAddress'],
      permanentAddress: map['permanentAddress'],
      iceName: map['iceName'],
      icePhone: map['icePhone'],
      bloodGroup: map['bloodGroup'],
    );
  }
}
