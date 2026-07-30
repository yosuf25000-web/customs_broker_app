import 'declaration_item.dart';

/// حالات الإقرار — يجب أن تطابق دورة الحياة في الـ Backend تماماً:
/// draft -> calculated -> approved (أو cancelled من أي حالة سابقة لـ approved).
enum DeclarationStatus { draft, calculated, approved, cancelled, unknown }

DeclarationStatus declarationStatusFromString(String? value) {
  switch (value) {
    case 'draft':
      return DeclarationStatus.draft;
    case 'calculated':
      return DeclarationStatus.calculated;
    case 'approved':
      return DeclarationStatus.approved;
    case 'cancelled':
      return DeclarationStatus.cancelled;
    default:
      return DeclarationStatus.unknown;
  }
}

class Declaration {
  final String id;
  final String internalNo;
  final String? customsManifestNo;
  final DateTime? declarationDate;
  final String traderId;
  final String? traderName;
  final DeclarationStatus status;
  final String? invoiceNo;
  final double customsValue;
  final double invoiceValue;
  final double freightValue;
  final double insuranceValue;
  final double otherExpenses;
  final String currencyCode;
  final double exchangeRate;
  final List<DeclarationItem> items;

  Declaration({
    required this.id,
    required this.internalNo,
    this.customsManifestNo,
    this.declarationDate,
    required this.traderId,
    this.traderName,
    required this.status,
    this.invoiceNo,
    this.customsValue = 0,
    this.invoiceValue = 0,
    this.freightValue = 0,
    this.insuranceValue = 0,
    this.otherExpenses = 0,
    this.currencyCode = 'USD',
    this.exchangeRate = 1,
    this.items = const [],
  });

  factory Declaration.fromJson(Map<String, dynamic> json) {
    return Declaration(
      id: json['id'] as String,
      internalNo: json['internal_no'] as String? ?? '',
      customsManifestNo: json['customs_manifest_no'] as String?,
      declarationDate: json['declaration_date'] != null ? DateTime.tryParse(json['declaration_date']) : null,
      traderId: json['trader_id'] as String? ?? '',
      traderName: json['trader_name'] as String?,
      status: declarationStatusFromString(json['status'] as String?),
      invoiceNo: json['invoice_no'] as String?,
      customsValue: double.tryParse('${json['customs_value'] ?? 0}') ?? 0,
      invoiceValue: double.tryParse('${json['invoice_value'] ?? 0}') ?? 0,
      freightValue: double.tryParse('${json['freight_value'] ?? 0}') ?? 0,
      insuranceValue: double.tryParse('${json['insurance_value'] ?? 0}') ?? 0,
      otherExpenses: double.tryParse('${json['other_expenses'] ?? 0}') ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'USD',
      exchangeRate: double.tryParse('${json['exchange_rate'] ?? 1}') ?? 1,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => DeclarationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get statusLabel {
    switch (status) {
      case DeclarationStatus.draft:
        return 'مسودة';
      case DeclarationStatus.calculated:
        return 'تم الحساب';
      case DeclarationStatus.approved:
        return 'معتمد';
      case DeclarationStatus.cancelled:
        return 'ملغى';
      case DeclarationStatus.unknown:
        return 'غير معروف';
    }
  }
}
