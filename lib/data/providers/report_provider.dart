// lib/providers/report_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReportProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Método para actualizar el estado de carga
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Método para actualizar el mensaje de error
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Método público para establecer un error
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Método público para limpiar el error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Método para subir imágenes y obtener sus URLs
  Future<List<String>> uploadImages(List<XFile> images) async {
    List<String> imageUrls = [];

    for (XFile image in images) {
      File file = File(image.path);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('reports_images')
          .child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await snapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    return imageUrls;
  }

  // Método para geocodificar una dirección
  Future<GeoPoint?> geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return GeoPoint(locations.first.latitude, locations.first.longitude);
      } else {
        _setError(
            'No se encontraron ubicaciones para la dirección proporcionada.');
        return null;
      }
    } catch (e) {
      _setError('Error al geocodificar la dirección: $e');
      return null;
    }
  }

  // Método para crear un reporte en Firestore
  Future<bool> createReport({
    required String type,
    required String description,
    required String category,
    required String visibility,
    required GeoPoint location,
    required String address,
    List<String>? images,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado.');
      }

      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user.uid,
        'type': type,
        'description': description,
        'location': location, // Uso de GeoPoint
        'timestamp': FieldValue.serverTimestamp(),
        'address': address,
        'status': 'pendiente', // Valor por defecto
        'images': images ?? [],
        'category': category,
        'comments': [], // Inicialmente vacío
        'rating': null, // Inicialmente nulo
        'visibility': visibility,
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear el reporte: $e');
      _setLoading(false);
      return false;
    }
  }
}
