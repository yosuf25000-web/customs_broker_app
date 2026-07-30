import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/document_item.dart';

class DocumentService {
  final ApiClient apiClient;
  DocumentService({required this.apiClient});

  Future<List<DocumentItem>> list({required String relatedType, required String relatedId}) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/documents', queryParameters: {
        'related_type': relatedType,
        'related_id': relatedId,
      });
      return (res.data['documents'] as List).map((e) => DocumentItem.fromJson(e)).toList();
    });
  }

  /// يرفع ملفاً من bytes (يعمل على كل المنصات، بخلاف الاعتماد على مسار ملف
  /// قد لا يكون متاحاً على الويب). fileName يجب أن يحتفظ بالامتداد الأصلي.
  Future<DocumentItem> upload({
    required String relatedType,
    required String relatedId,
    required String docType,
    required List<int> bytes,
    required String fileName,
  }) {
    return apiClient.guard(() async {
      final formData = FormData.fromMap({
        'related_type': relatedType,
        'related_id': relatedId,
        'doc_type': docType,
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final res = await apiClient.dio.post('/documents/upload', data: formData);
      return DocumentItem.fromJson(res.data['document']);
    });
  }

  Future<void> delete(String documentId) {
    return apiClient.guard(() async {
      await apiClient.dio.delete('/documents/$documentId');
    });
  }

  /// رابط التنزيل/العرض المباشر (يُستخدم كـ Authorization header يُضاف تلقائياً
  /// من الـ Interceptor عند فتحه ضمن التطبيق؛ لعرضه في متصفح خارجي يلزم تمرير التوكن يدوياً).
  String downloadUrl(String documentId) => '${ApiConfig.baseUrl}/documents/$documentId/download';
}
