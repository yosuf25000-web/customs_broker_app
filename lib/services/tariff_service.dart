import '../core/api_client.dart';
import '../models/tariff_code_suggestion.dart';

class TariffService {
  final ApiClient apiClient;
  TariffService({required this.apiClient});

  /// بحث اقتراحي فقط — المخلص الجمركي هو من يختار ويعتمد البند يدوياً دائماً.
  Future<List<TariffCodeSuggestion>> search(String query) {
    return apiClient.guard(() async {
      if (query.trim().length < 2) return <TariffCodeSuggestion>[];
      final response = await apiClient.dio.get('/tariff-codes/search', queryParameters: {'q': query.trim()});
      final results = response.data['results'] as List<dynamic>;
      return results.map((e) => TariffCodeSuggestion.fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}
