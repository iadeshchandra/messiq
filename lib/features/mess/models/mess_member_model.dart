class MessMemberModel {
  final String uid;
  final String role; // 'manager', 'co-manager', 'member', 'viewer'
  final String status; // 'approved', 'pending'
  final DateTime joinedAt;

  MessMemberModel({
    required this.uid,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'status': status,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory MessMemberModel.fromMap(Map<String, dynamic> map) {
    return MessMemberModel(
      uid: map['uid'] ?? '',
      role: map['role'] ?? 'member',
      status: map['status'] ?? 'pending',
      joinedAt: DateTime.parse(map['joinedAt']),
    );
  }
}
