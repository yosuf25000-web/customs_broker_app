class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? tenantId;

  AppUser({required this.id, required this.fullName, required this.email, this.tenantId});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      tenantId: json['tenant_id'] as String?,
    );
  }
}
