class MessModel {
  final String id;
  final String name;
  final String inviteCode;
  final String managerId;
  final DateTime createdAt;

  MessModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.managerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'managerId': managerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MessModel.fromMap(Map<String, dynamic> map) {
    return MessModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      managerId: map['managerId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
