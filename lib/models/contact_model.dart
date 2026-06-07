// Roadmap Section 4.1 ER Diagram:
// Contact: id, name, mobile, email, type (borrower/lender), createdAt
class Contact {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String type; // 'borrower' or 'lender'
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      name: map['name'],
      mobile: map['mobile'],
      email: map['email'],
      type: map['type'] ?? 'borrower',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Contact copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? type,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
