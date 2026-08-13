import 'package:cloud_firestore/cloud_firestore.dart';

class LostItem {
  final String title;
  final String description;
  final String location;
  final String status;
  final String postedBy;
  final DateTime timestamp;

  LostItem({
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.postedBy,
    required this.timestamp,
  });


  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'status': status,
      'postedBy': postedBy,
      'timestamp': timestamp,
    };
  }
}