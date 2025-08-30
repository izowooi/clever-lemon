class UserInfo {
  final String id;
  final String name;
  final String email;

  const UserInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };

  @override
  String toString() => toJson().toString();
}


