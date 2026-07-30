class Trader {
  final String id;
  final String name;
  final String? taxNo;
  final String? commercialRegister;
  final String? phone;
  final String? address;
  final String? contactPerson;
  final double currentBalance;
  final bool isActive;

  Trader({
    required this.id,
    required this.name,
    this.taxNo,
    this.commercialRegister,
    this.phone,
    this.address,
    this.contactPerson,
    this.currentBalance = 0,
    this.isActive = true,
  });

  factory Trader.fromJson(Map<String, dynamic> json) {
    return Trader(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      taxNo: json['tax_no'] as String?,
      commercialRegister: json['commercial_register'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      contactPerson: json['contact_person'] as String?,
      currentBalance: double.tryParse('${json['current_balance'] ?? 0}') ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
