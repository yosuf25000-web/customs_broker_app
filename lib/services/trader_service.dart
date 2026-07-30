import '../core/api_client.dart';
import '../models/trader.dart';

class TraderService {
  final ApiClient apiClient;
  TraderService({required this.apiClient});

  Future<List<Trader>> list({String? query}) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.get('/traders', queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
      });
      final list = response.data['traders'] as List<dynamic>;
      return list.map((e) => Trader.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<Trader> create({
    required String name,
    String? taxNo,
    String? commercialRegister,
    String? phone,
    String? address,
    String? contactPerson,
  }) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.post('/traders', data: {
        'name': name,
        if (taxNo != null && taxNo.isNotEmpty) 'tax_no': taxNo,
        if (commercialRegister != null && commercialRegister.isNotEmpty) 'commercial_register': commercialRegister,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (contactPerson != null && contactPerson.isNotEmpty) 'contact_person': contactPerson,
      });
      return Trader.fromJson(response.data['trader'] as Map<String, dynamic>);
    });
  }

  Future<Trader> getById(String id) {
    return apiClient.guard(() async {
      final response = await apiClient.dio.get('/traders/$id');
      return Trader.fromJson(response.data['trader'] as Map<String, dynamic>);
    });
  }
}
