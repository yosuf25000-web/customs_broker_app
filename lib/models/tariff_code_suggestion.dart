class TariffCodeSuggestion {
  final String id;
  final String hsCode;
  final String description;
  final String? unitDefault;

  TariffCodeSuggestion({
    required this.id,
    required this.hsCode,
    required this.description,
    this.unitDefault,
  });

  factory TariffCodeSuggestion.fromJson(Map<String, dynamic> json) {
    return TariffCodeSuggestion(
      id: json['id'] as String,
      hsCode: json['hs_code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      unitDefault: json['unit_default'] as String?,
    );
  }
}
