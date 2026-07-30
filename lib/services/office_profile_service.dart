import 'package:dio/dio.dart';
import '../core/api_client.dart';

class OfficeProfile {
  final String officeName;
  final String brokerName;
  final String? licenseNo;
  final String? phone;
  final String? address;
  final String officeCode;
  final bool hasLogo;

  OfficeProfile({
    required this.officeName, required this.brokerName, this.licenseNo,
    this.phone, this.address, required this.officeCode, required this.hasLogo,
  });

  factory OfficeProfile.fromJson(Map<String, dynamic> json) => OfficeProfile(
        officeName: json['office_name'] as String? ?? '',
        brokerName: json['broker_name'] as String? ?? '',
        licenseNo: json['license_no'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        officeCode: json['office_code'] as String? ?? '',
        hasLogo: json['logo_url'] != null,
      );
}

class OfficeProfileService {
  final ApiClient apiClient;
  OfficeProfileService({required this.apiClient});

  Future<OfficeProfile> get() {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/tenant/profile');
      return OfficeProfile.fromJson(res.data['tenant']);
    });
  }

  Future<OfficeProfile> update({
    String? officeName, String? brokerName, String? licenseNo, String? phone, String? address,
  }) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.patch('/tenant/profile', data: {
        if (officeName != null) 'office_name': officeName,
        if (brokerName != null) 'broker_name': brokerName,
        if (licenseNo != null) 'license_no': licenseNo,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      });
      return OfficeProfile.fromJson(res.data['tenant']);
    });
  }

  Future<void> uploadLogo({required List<int> bytes, required String fileName}) {
    return apiClient.guard(() async {
      final formData = FormData.fromMap({'logo': MultipartFile.fromBytes(bytes, filename: fileName)});
      await apiClient.dio.post('/tenant/profile/logo', data: formData);
    });
  }
}
