import '../core/api_client.dart';
import '../core/secure_storage_service.dart';
import '../models/app_user.dart';

class LoginResult {
  final AppUser user;
  final bool isSuperAdmin;
  LoginResult({required this.user, required this.isSuperAdmin});
}

class AuthService {
  final ApiClient apiClient;
  final SecureStorageService storage;

  AuthService({required this.apiClient, required this.storage});

  /// دخول مستخدم مكتب: يتطلب رمز المكتب (office_code) دائماً، لأن البريد
  /// فريد فقط ضمن نطاق المكتب وليس عالمياً.
  Future<LoginResult> loginOffice({
    required String officeCode,
    required String email,
    required String password,
  }) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.post('/auth/login', data: {
        'office_code': officeCode.trim().toUpperCase(),
        'email': email.trim(),
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      await storage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      await storage.saveLastOfficeCode(officeCode.trim().toUpperCase());
      await storage.setIsSuperAdmin(false);
      return LoginResult(user: AppUser.fromJson(data['user']), isSuperAdmin: false);
    });
  }

  /// دخول مالك النظام (Super Admin) — بدون office_code.
  Future<LoginResult> loginSuperAdmin({required String email, required String password}) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.post('/auth/super-admin/login', data: {
        'email': email.trim(),
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      await storage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      await storage.setIsSuperAdmin(true);
      return LoginResult(user: AppUser.fromJson(data['user']), isSuperAdmin: true);
    });
  }

  /// تسجيل خروج من هذا الجهاز فقط.
  Future<void> logout() async {
    final refreshToken = await storage.getRefreshToken();
    try {
      if (refreshToken != null) {
        await apiClient.dio.post('/auth/logout', data: {'refresh_token': refreshToken});
      }
    } catch (_) {
      // حتى لو فشل الطلب (لا اتصال مثلاً)، نمسح الجلسة محلياً دائماً
    } finally {
      await storage.clearSession();
    }
  }

  /// تسجيل خروج من كل الأجهزة (Logout All).
  Future<void> logoutAllDevices() async {
    final refreshToken = await storage.getRefreshToken();
    try {
      if (refreshToken != null) {
        await apiClient.dio.post('/auth/logout-all', data: {'refresh_token': refreshToken});
      }
    } finally {
      await storage.clearSession();
    }
  }

  Future<bool> hasActiveSession() async {
    final token = await storage.getAccessToken();
    return token != null;
  }
}
