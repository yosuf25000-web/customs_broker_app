class DeclarationItem {
  final String id;
  final String? tariffCodeId;
  final String? hsCode;
  final String? tariffDescription;
  final String goodsDescription;
  final String? originCountry;
  final double quantity;
  final String? unit;
  final double? grossWeight;
  final double? netWeight;
  final double itemValue;
  final String currencyCode;
  final double exchangeRate;
  final double? totalItemFees;
  final String? warning;

  DeclarationItem({
    required this.id,
    this.tariffCodeId,
    this.hsCode,
    this.tariffDescription,
    required this.goodsDescription,
    this.originCountry,
    this.quantity = 0,
    this.unit,
    this.grossWeight,
    this.netWeight,
    this.itemValue = 0,
    this.currencyCode = 'USD',
    this.exchangeRate = 1,
    this.totalItemFees,
    this.warning,
  });

  factory DeclarationItem.fromJson(Map<String, dynamic> json) {
    final feesSnapshot = json['other_fees_snapshot'];
    String? warning;
    if (feesSnapshot is Map && feesSnapshot['warning'] != null) {
      warning = feesSnapshot['warning'].toString();
    }
    return DeclarationItem(
      id: json['id'] as String,
      tariffCodeId: json['tariff_code_id'] as String?,
      hsCode: json['hs_code'] as String?,
      tariffDescription: json['tariff_description'] as String?,
      goodsDescription: json['goods_description'] as String? ?? '',
      originCountry: json['origin_country'] as String?,
      quantity: double.tryParse('${json['quantity'] ?? 0}') ?? 0,
      unit: json['unit'] as String?,
      grossWeight: json['gross_weight'] != null ? double.tryParse('${json['gross_weight']}') : null,
      netWeight: json['net_weight'] != null ? double.tryParse('${json['net_weight']}') : null,
      itemValue: double.tryParse('${json['item_value'] ?? 0}') ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'USD',
      exchangeRate: double.tryParse('${json['exchange_rate'] ?? 1}') ?? 1,
      totalItemFees: json['total_item_fees'] != null ? double.tryParse('${json['total_item_fees']}') : null,
      warning: warning,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      if (tariffCodeId != null) 'tariff_code_id': tariffCodeId,
      'goods_description': goodsDescription,
      if (originCountry != null) 'origin_country': originCountry,
      'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (grossWeight != null) 'gross_weight': grossWeight,
      if (netWeight != null) 'net_weight': netWeight,
      'item_value': itemValue,
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate,
    };
  }
}
