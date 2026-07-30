import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/document_item.dart';
import '../services/document_service.dart';

class DocumentsSection extends StatefulWidget {
  final String relatedType; // declaration | trader
  final String relatedId;
  final ApiClient apiClient;
  final bool readOnly;

  const DocumentsSection({
    super.key,
    required this.relatedType,
    required this.relatedId,
    required this.apiClient,
    this.readOnly = false,
  });

  @override
  State<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection> {
  late final DocumentService _service = DocumentService(apiClient: widget.apiClient);
  List<DocumentItem> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _service.list(relatedType: widget.relatedType, relatedId: widget.relatedId);
      if (mounted) setState(() => _documents = docs);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocType() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: documentTypeLabels.entries
              .map((e) => ListTile(title: Text(e.value), onTap: () => Navigator.of(context).pop(e.key)))
              .toList(),
        ),
      ),
    );
    if (selected == null) return;
    await _pickAndUpload(selected);
  }

  Future<void> _pickAndUpload(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true, // نطلب bytes مباشرة ليعمل على كل المنصات (ويب/موبايل)
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر قراءة الملف المختار')));
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _service.upload(
        relatedType: widget.relatedType,
        relatedId: widget.relatedId,
        docType: docType,
        bytes: file.bytes!,
        fileName: file.name,
      );
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _delete(String documentId) async {
    try {
      await _service.delete(documentId);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('المستندات (${_documents.length})', style: Theme.of(context).textTheme.titleSmall),
            if (!widget.readOnly)
              TextButton.icon(
                onPressed: _isUploading ? null : _pickDocType,
                icon: _isUploading
                    ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_outlined),
                label: const Text('رفع مستند'),
              ),
          ],
        ),
        if (_isLoading)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else if (_documents.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('لا توجد مستندات مرفوعة بعد', style: TextStyle(color: Colors.grey)))
        else
          ..._documents.map((doc) => Card(
                child: ListTile(
                  leading: Icon(doc.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined),
                  title: Text(doc.docTypeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${doc.originalFilename} • ${doc.sizeLabel}'),
                  trailing: widget.readOnly
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _delete(doc.id),
                        ),
                ),
              )),
      ],
    );
  }
}
