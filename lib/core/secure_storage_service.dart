import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// تخزين آمن (Keystore على أندرويد / Keychain على iOS) للتوكنات.
/// لا تُخزَّن كلمة المرور أبداً هنا، فقط التوكنات وهوية آخر مكتب استُخدم به الدخول.
class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _lastOfficeCodeKey = 'last_office_code';
  static const _isSuperAdminKey = 'is_super_admin';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveAccessTokenOnly(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveLastOfficeCode(String code) => _storage.write(key: _lastOfficeCodeKey, value: code);
  Future<String?> getLastOfficeCode() => _storage.read(key: _lastOfficeCodeKey);

  Future<void> setIsSuperAdmin(bool value) => _storage.write(key: _isSuperAdminKey, value: value.toString());
  Future<bool> getIsSuperAdmin() async => (await _storage.read(key: _isSuperAdminKey)) == 'true';

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _isSuperAdminKey);
    // نُبقي last_office_code لتسهيل إعادة الدخول اللاحقة
  }
}
