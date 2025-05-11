class Complaint {
  final String id;
  final String content;
  final DateTime createdAt;

  Complaint({required this.id, required this.content, required this.createdAt});

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
