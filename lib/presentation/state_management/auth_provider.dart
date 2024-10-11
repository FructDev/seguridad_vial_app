// lib/presentation/state_management/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  User? get user => _user;

  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Escuchar cambios en el estado de autenticación
    _auth.authStateChanges().listen(_authStateChanges);
  }

  void _authStateChanges(User? user) {
    _user = user;
    notifyListeners();
  }

  // Método para registrar un nuevo usuario
  Future<void> signUp({required String email, required String password}) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      notifyListeners();
    } catch (e) {
      // Manejo de errores
      rethrow;
    }
  }

  // Método para iniciar sesión
  Future<void> signIn({required String email, required String password}) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      notifyListeners();
    } catch (e) {
      // Manejo de errores
      rethrow;
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
