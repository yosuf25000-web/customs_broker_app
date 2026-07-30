import 'dart:async';
import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'secure_storage_service.dart';

/// إعدادات الاتصال بالـ Backend.
/// * محاكي أندرويد: يستخدم 10.0.2.2 للوصول لـ localhost على جهاز التطوير.
/// * جهاز حقيقي / إنتاج: استبدل بعنوان الخادم الفعلي (https://api.yourdomain.com).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );
}

/// عميل HTTP مركزي: يحقن Access Token تلقائياً في كل طلب، ويحاول تجديد
/// الجلسة تلقائياً (مرة واحدة) عند استلام 401 قبل إعادة تنفيذ الطلب الأصلي.
/// عند فشل التجديد (مثال: REFRESH_TOKEN_REUSED) يُستدعى [onSessionExpired]
/// ليقوم الطرف المستدعي (AuthProvider) بإعادة توجيه المستخدم لشاشة الدخول.
class ApiClient {
  final Dio dio;
  final SecureStorageService storage;
  void Function()? onSessionExpired;

  Completer<void>? _refreshCompleter;

  ApiClient({SecureStorageService? storage})
      : storage = storage ?? SecureStorageService(),
        dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await this.storage.getAccessToken();
        if (token != null && !options.path.startsWith('/auth/')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        final statusCode = error.response?.statusCode;
        final requestPath = error.requestOptions.path;

        final isAuthEndpoint = requestPath.startsWith('/auth/');
        if (statusCode == 401 && !isAuthEndpoint) {
          try {
            await _refreshAccessToken();
            final cloned = await _retry(error.requestOptions);
            return handler.resolve(cloned);
          } catch (_) {
            onSessionExpired?.call();
            return handler.next(error);
          }
        }
        handler.next(error);
      },
    ));
  }

  /// يمنع تشغيل عدة طلبات تجديد متزامنة: إن كان تجديد قيد التنفيذ بالفعل،
  /// تنتظر الطلبات الأخرى نتيجته بدل إطلاق طلبات /auth/refresh متعددة.
  Future<void> _refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<void>();
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null) {
        throw ApiException(code: 'INVALID_REFRESH_TOKEN', message: 'لا توجد جلسة محفوظة');
      }
      final response = await dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String?;
      await storage.saveAccessTokenOnly(newAccessToken);
      if (newRefreshToken != null) {
        await storage.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
      }
      _refreshCompleter!.complete();
    } catch (err) {
      await storage.clearSession();
      _refreshCompleter!.completeError(err);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await storage.getAccessToken();
    final options = Options(method: requestOptions.method, headers: {
      ...requestOptions.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    });
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// غلاف موحّد لتحويل أي خطأ Dio إلى [ApiException] بصيغة موحّدة للاستخدام في الواجهات.
  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      if (e.response?.data != null) {
        throw ApiException.fromResponseData(e.response!.data, statusCode: e.response!.statusCode);
      }
      throw ApiException(
        code: 'NETWORK_ERROR',
        message: 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت.',
      );
    }
  }
}
