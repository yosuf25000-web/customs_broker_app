import '../core/api_client.dart';
import '../models/declaration.dart';
import '../models/declaration_item.dart';

/// نتيجة تشغيل محرك الحساب — breakdown كامل لكل صنف + إجماليات الإقرار.
/// راجع docs/CALCULATION_ENGINE.md في الـ Backend لتفاصيل كل حقل.
class CalculationResult {
  final String totalCustomsValue;
  final Map<String, dynamic> totals;
  final List<dynamic> items;
  final List<dynamic> declarationLevelFees;

  CalculationResult({
    required this.totalCustomsValue,
    required this.totals,
    required this.items,
    required this.declarationLevelFees,
  });

  factory CalculationResult.fromJson(Map<String, dynamic> json) {
    return CalculationResult(
      totalCustomsValue: json['total_customs_value']?.toString() ?? '0.00',
      totals: Map<String, dynamic>.from(json['totals'] as Map? ?? {}),
      items: json['items'] as List<dynamic>? ?? [],
      declarationLevelFees: json['declaration_level_fees'] as List<dynamic>? ?? [],
    );
  }
}

class DeclarationService {
  final ApiClient apiClient;
  DeclarationService({required this.apiClient});

  Future<List<Declaration>> list({String? traderId, String? status}) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.get('/declarations', queryParameters: {
        if (traderId != null) 'trader_id': traderId,
        if (status != null) 'status': status,
      });
      final list = response.data['declarations'] as List<dynamic>;
      return list.map((e) => Declaration.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<Declaration> getById(String id) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.get('/declarations/$id');
      return Declaration.fromJson(response.data['declaration'] as Map<String, dynamic>);
    });
  }

  Future<Declaration> create({
    required String traderId,
    String? customsOfficeId,
    String? invoiceNo,
    String currencyCode = 'USD',
    double exchangeRate = 1,
    double invoiceValue = 0,
    double freightValue = 0,
    double insuranceValue = 0,
    double otherExpenses = 0,
    List<DeclarationItem> items = const [],
  }) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.post('/declarations', data: {
        'trader_id': traderId,
        if (customsOfficeId != null) 'customs_office_id': customsOfficeId,
        if (invoiceNo != null && invoiceNo.isNotEmpty) 'invoice_no': invoiceNo,
        'currency_code': currencyCode,
        'exchange_rate': exchangeRate,
        'invoice_value': invoiceValue,
        'freight_value': freightValue,
        'insurance_value': insuranceValue,
        'other_expenses': otherExpenses,
        'items': items.map((e) => e.toCreateJson()).toList(),
      });
      return Declaration.fromJson(response.data['declaration'] as Map<String, dynamic>);
    });
  }

  Future<void> addItem(String declarationId, DeclarationItem item) {
    return apiClient.guard(() async {
      await apiClient.dio.post('/declarations/$declarationId/items', data: item.toCreateJson());
    });
  }

  Future<void> deleteItem(String declarationId, String itemId) {
    return apiClient.guard(() async {
      await apiClient.dio.delete('/declarations/$declarationId/items/$itemId');
    });
  }

  /// يشغّل محرك الحساب. لا يعتمد الإقرار. الحالة تنتقل إلى "calculated".
  Future<CalculationResult> calculate(String declarationId, {String allocationMethod = 'BY_ITEM_VALUE'}) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.post(
        '/declarations/$declarationId/calculate',
        data: {'allocation_method': allocationMethod},
      );
      return CalculationResult.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// يعتمد الإقرار. يفشل إن لم يكن قد جرى حسابه، أو إن تغيّرت البيانات بعد آخر حساب
  /// (STALE_CALCULATION) — في هذه الحالة يجب استدعاء calculate() مجدداً.
  Future<Declaration> approve(String declarationId) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.post('/declarations/$declarationId/approve');
      return Declaration.fromJson(response.data['declaration'] as Map<String, dynamic>);
    });
  }

  /// إعادة فتح إقرار معتمد للتعديل (Amendment) — يتطلب صلاحية خاصة وسبباً إلزامياً.
  Future<Declaration> reopen(String declarationId, String reason) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.post('/declarations/$declarationId/reopen', data: {'reason': reason});
      return Declaration.fromJson(response.data['declaration'] as Map<String, dynamic>);
    });
  }
}
