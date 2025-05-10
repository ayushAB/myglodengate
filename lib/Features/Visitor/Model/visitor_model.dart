class Visitor {
  final String id;
  final String name;
  final String purpose;
  final String status;

  Visitor({
    required this.id,
    required this.name,
    required this.purpose,
    required this.status,
  });

  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      id: map['id'],
      name: map['name'],
      purpose: map['purpose'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}
