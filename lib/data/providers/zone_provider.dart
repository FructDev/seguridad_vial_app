import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<RiskZone> _zones = [];
  List<RiskZone> get zones => _zones;

  Future<void> fetchRiskZones() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('risk_zones').get();
      _zones = snapshot.docs.map((doc) {
        return RiskZone.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error al obtener las zonas de riesgo: $e');
    }
  }

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  void listenToReports() {
    _firestore.collection('reports').snapshots().listen((snapshot) {
      _reports = snapshot.docs.map((doc) {
        return Report.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      notifyListeners();
    });
  }

  Future<void> updateReportStatus(String reportId, String newStatus) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': newStatus,
    });
  }

  Future<void> updateReportRating(String reportId, double newRating) async {
    await _firestore.collection('reports').doc(reportId).update({
      'rating': newRating,
    });
  }

  Future<void> addCommentToReport(String reportId, String comment) async {
    await _firestore.collection('reports').doc(reportId).update({
      'comments': FieldValue.arrayUnion([comment]),
    });
  }
}

class RiskZone {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final int level;

  RiskZone({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.level,
  });

  factory RiskZone.fromMap(Map<String, dynamic> data, String documentId) {
    return RiskZone(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      level: data['level'] ?? 1,
    );
  }
}

class Report {
  final String id;
  final String userId;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final String category;
  final String status;
  final List<String> images;
  final List<String> comments;
  final double? rating;
  final Timestamp timestamp;

  Report({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.category,
    required this.status,
    required this.images,
    required this.comments,
    this.rating,
    required this.timestamp,
  });

  factory Report.fromMap(Map<String, dynamic> data, String documentId) {
    return Report(
      id: documentId,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['location'] as GeoPoint).latitude,
      longitude: (data['location'] as GeoPoint).longitude,
      address: data['address'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'pendiente',
      images: List<String>.from(data['images'] ?? []),
      comments: List<String>.from(data['comments'] ?? []),
      rating: data['rating'] != null ? data['rating'].toDouble() : null,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
