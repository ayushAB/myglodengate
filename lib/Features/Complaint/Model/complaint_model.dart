class Complaint {
  final String id;
  final String title;
  final String description;

  Complaint({required this.id, required this.title, required this.description});

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
    );
  }
}
