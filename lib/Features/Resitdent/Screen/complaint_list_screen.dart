import 'package:flutter/material.dart';
import 'package:myglodengate/Features/Resitdent/Model/complaint.dart';
import 'package:myglodengate/Features/Resitdent/Services/complaint_service.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  final _service = ComplaintService();
  late Future<List<Complaint>> _complaints;

  @override
  void initState() {
    super.initState();
    _complaints = _service.fetchMyComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: FutureBuilder<List<Complaint>>(
        future: _complaints,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(child: Text('No complaints found.'));
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final complaint = data[i];
              return ListTile(
                title: Text(complaint.content),
                subtitle: Text(complaint.createdAt.toLocal().toString()),
              );
            },
          );
        },
      ),
    );
  }
}
