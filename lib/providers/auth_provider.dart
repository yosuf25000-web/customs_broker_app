import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/secure_storage_service.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  final ApiClient apiClient;
  final SecureStorageService storage;

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  bool isSuperAdmin = false;
  String? lastError;
  bool isLoading = false;

  AuthProvider({required this.authService, required this.apiClient, required this.storage}) {
    // عند فشل تجديد الجلسة تلقائياً (Reuse Detection مثلاً)، نعيد المستخدم لشاشة الدخول فوراً
    apiClient.onSessionExpired = () {
      currentUser = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
    };
  }

  Future<void> restoreSession() async {
    final hasSession = await authService.hasActiveSession();
    isSuperAdmin = await storage.getIsSuperAdmin();
    status = hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> loginOffice({required String officeCode, required String email, required String password}) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await authService.loginOffice(officeCode: officeCode, email: email, password: password);
      currentUser = result.user;
      isSuperAdmin = false;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      lastError = e.displayMessage;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginSuperAdmin({required String email, required String password}) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await authService.loginSuperAdmin(email: email, password: password);
      currentUser = result.user;
      isSuperAdmin = true;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      lastError = e.displayMessage;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logoutAllDevices() async {
    await authService.logoutAllDevices();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
