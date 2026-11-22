import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/app_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? DemoAuthRepository();

  final AuthRepository _repository;
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> restoreSession() async {
    try {
      _user = await _repository.restoreSession();
    } catch (_) {
      _user = null;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _repository.signIn(email, password);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(
      {required String name,
      required String email,
      required String password,
      required UserRole role}) async {
    _setLoading(true);
    try {
      _user = await _repository.register(
          name: name, email: email, password: password, role: role);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _repository.resetPassword(email);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
