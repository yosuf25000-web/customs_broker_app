/// يمثّل خطأ قادماً من الـ API بصيغته الموحدة:
/// { "success": false, "error": { "code": "...", "message": "..." } }
/// راجع src/utils/apiError.js في الـ Backend لقائمة الرموز الكاملة.
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiException.fromResponseData(dynamic data, {int? statusCode}) {
    try {
      final error = data is Map ? data['error'] : null;
      if (error is Map) {
        return ApiException(
          code: (error['code'] ?? 'UNKNOWN_ERROR').toString(),
          message: (error['message'] ?? 'حدث خطأ غير متوقع').toString(),
          statusCode: statusCode,
          details: error['details'],
        );
      }
    } catch (_) {
      // تجاهل ونستخدم القيمة الافتراضية أدناه
    }
    return ApiException(
      code: 'UNKNOWN_ERROR',
      message: 'حدث خطأ غير متوقع. تحقق من الاتصال بالإنترنت وحاول مجدداً.',
      statusCode: statusCode,
    );
  }

  /// رسالة مناسبة للعرض للمستخدم، بعربية مبسطة لأشهر رموز الأخطاء،
  /// مع رجوع للرسالة القادمة من الخادم إن لم يوجد نص محلي مخصص.
  String get displayMessage {
    switch (code) {
      case 'SUBSCRIPTION_EXPIRED':
        return 'انتهى اشتراك المكتب. يرجى التواصل مع الدعم لتجديد الاشتراك.';
      case 'TENANT_SUSPENDED':
        return 'تم إيقاف حساب المكتب. يرجى التواصل مع الدعم.';
      case 'USER_SUSPENDED':
        return 'تم إيقاف هذا المستخدم من قبل مدير المكتب.';
      case 'INVALID_OFFICE_CODE':
        return 'رمز المكتب غير صحيح.';
      case 'INVALID_CREDENTIALS':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'REFRESH_TOKEN_REUSED':
        return 'تم إنهاء جلستك لأسباب أمنية. يرجى تسجيل الدخول من جديد.';
      case 'AMBIGUOUS_TARIFF_RULE':
        return 'يوجد تعارض في قواعد التعرفة لهذا البند. يرجى التواصل مع الإدارة.';
      case 'STALE_CALCULATION':
        return 'تغيّرت بيانات الإقرار منذ آخر حساب. أعد الحساب قبل الاعتماد.';
      case 'DECLARATION_NOT_CALCULATED':
        return 'يجب تشغيل الحساب أولاً قبل اعتماد الإقرار.';
      case 'DECLARATION_LOCKED':
        return 'الإقرار معتمد ولا يمكن تعديله مباشرة. استخدم إعادة الفتح أولاً.';
      case 'FORBIDDEN':
        return 'لا تملك صلاحية تنفيذ هذا الإجراء.';
      case 'LIMIT_REACHED':
        return 'تم الوصول للحد الأقصى المسموح به في باقتك الحالية.';
      case 'NOT_FOUND':
        return 'العنصر المطلوب غير موجود.';
      default:
        return message;
    }
  }
}
