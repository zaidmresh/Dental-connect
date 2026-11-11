// lib/services/auth_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedUsers = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get hasLoadedUsers => _hasLoadedUsers;
  List<UserModel> get dentists => _users.values
      .where((entry) => entry['user'] is Map)
      .map((entry) =>
          UserModel.fromJson(Map<String, dynamic>.from(entry['user'])))
      .where((user) => user.role == UserRole.dentist)
      .toList();
  List<UserModel> get labs => _users.values
      .where((entry) => entry['user'] is Map)
      .map((entry) =>
          UserModel.fromJson(Map<String, dynamic>.from(entry['user'])))
      .where((user) => user.role == UserRole.technician)
      .toList();

  final Map<String, Map<String, dynamic>> _users = {};

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  AuthProvider() {
    _loadUsers();
  }

  Future<void> loadUsers() => _loadUsers();

  Future<void> _loadUsers() async {
    if (_hasLoadedUsers) return;

    try {
      final snapshot = await _firestore.collection('users').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['user'] is Map) {
          final userData = Map<String, dynamic>.from(data['user']);
          if (userData['role'] == 'patient') {
            continue;
          }
        }
        _users[doc.id] = data;
      }
    } catch (_) {
      // Keep demo/in-memory accounts available if Firestore is unavailable.
    }
    _hasLoadedUsers = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800)); // simulate network
    await _loadUsers();

    final userEntry = _users[_normalizeEmail(email)];
    if (userEntry == null || userEntry['password'] != password) {
      _error = 'Invalid email or password.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _currentUser = UserModel.fromJson(userEntry['user']);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? clinicOrLabName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    await _loadUsers();

    final normalizedEmail = _normalizeEmail(email);
    if (_users.containsKey(normalizedEmail)) {
      _error = 'An account with this email already exists.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final newId = const Uuid().v4();
    final userData = {
      'id': newId,
      'fullName': fullName.trim(),
      'email': normalizedEmail,
      'role': role == UserRole.technician ? 'technician' : 'dentist',
      'clinicOrLabName': clinicOrLabName,
    };

    _users[normalizedEmail] = {
      'password': password,
      'user': userData,
    };
    try {
      await _firestore.collection('users').doc(normalizedEmail).set({
        'password': password,
        'user': userData,
      });
    } catch (_) {}

    _currentUser = UserModel.fromJson(userData);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> updateAvailabilityTimes(List<String> times) async {
    if (_currentUser == null) return;

    final current = _currentUser!;
    final updatedUser = UserModel(
      id: current.id,
      fullName: current.fullName,
      email: current.email,
      role: current.role,
      clinicOrLabName: current.clinicOrLabName,
      address: current.address,
      availabilityTimes: times,
    );

    _currentUser = updatedUser;
    final normalizedEmail = _normalizeEmail(updatedUser.email);
    if (_users.containsKey(normalizedEmail)) {
      _users[normalizedEmail]!['user'] = updatedUser.toJson();
    } else {
      _users[normalizedEmail] = {
        'password': '',
        'user': updatedUser.toJson(),
      };
    }

    try {
      await _firestore.collection('users').doc(normalizedEmail).set(
        {
          'password': _users[normalizedEmail]!['password'],
          'user': updatedUser.toJson(),
        },
      );
    } catch (_) {}
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
