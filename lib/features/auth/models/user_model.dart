class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? activeMessId;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.activeMessId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'activeMessId': activeMessId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      activeMessId: map['activeMessId'],
    );
  }
}
