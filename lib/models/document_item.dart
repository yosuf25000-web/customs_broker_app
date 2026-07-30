const Map<String, String> documentTypeLabels = {
  'bill_of_lading': 'بوليصة الشحن',
  'commercial_invoice': 'الفاتورة التجارية',
  'certificate_of_origin': 'شهادة المنشأ',
  'packing_list': 'قائمة التعبئة',
  'permit': 'تصريح',
  'goods_photo': 'صورة بضاعة',
  'customs_declaration_form': 'نموذج الإقرار الجمركي',
  'payment_receipt': 'إيصال سداد',
  'vehicle_photo': 'صورة شاحنة/مركبة',
  'other': 'أخرى',
};

class DocumentItem {
  final String id;
  final String docType;
  final String originalFilename;
  final String mimeType;
  final int fileSizeBytes;
  final DateTime uploadedAt;

  DocumentItem({
    required this.id, required this.docType, required this.originalFilename,
    required this.mimeType, required this.fileSizeBytes, required this.uploadedAt,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
        id: json['id'] as String,
        docType: json['doc_type'] as String? ?? 'other',
        originalFilename: json['original_filename'] as String? ?? '',
        mimeType: json['mime_type'] as String? ?? '',
        fileSizeBytes: int.tryParse('${json['file_size_bytes'] ?? 0}') ?? 0,
        uploadedAt: DateTime.tryParse(json['uploaded_at'] ?? '') ?? DateTime.now(),
      );

  String get docTypeLabel => documentTypeLabels[docType] ?? docType;
  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  String get sizeLabel {
    if (fileSizeBytes < 1024) return '$fileSizeBytes بايت';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(0)} كيلوبايت';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
  }
}
