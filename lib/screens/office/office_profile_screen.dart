import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../services/office_profile_service.dart';

class OfficeProfileScreen extends StatefulWidget {
  const OfficeProfileScreen({super.key});

  @override
  State<OfficeProfileScreen> createState() => _OfficeProfileScreenState();
}

class _OfficeProfileScreenState extends State<OfficeProfileScreen> {
  late final OfficeProfileService _service = OfficeProfileService(apiClient: context.read<ApiClient>());
  OfficeProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;

  final _officeNameController = TextEditingController();
  final _brokerNameController = TextEditingController();
  final _licenseNoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _service.get();
      setState(() {
        _profile = profile;
        _officeNameController.text = profile.officeName;
        _brokerNameController.text = profile.brokerName;
        _licenseNoController.text = profile.licenseNo ?? '';
        _phoneController.text = profile.phone ?? '';
        _addressController.text = profile.address ?? '';
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _service.update(
        officeName: _officeNameController.text.trim(),
        brokerName: _brokerNameController.text.trim(),
        licenseNo: _licenseNoController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات المكتب')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;

    setState(() => _isUploadingLogo = true);
    try {
      await _service.uploadLogo(bytes: result.files.first.bytes!, fileName: result.files.first.name);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الشعار')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  @override
  void dispose() {
    _officeNameController.dispose();
    _brokerNameController.dispose();
    _licenseNoController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات المكتب')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.teal.shade50,
                        child: _isUploadingLogo
                            ? const CircularProgressIndicator()
                            : Icon(
                                (_profile?.hasLogo ?? false) ? Icons.business : Icons.add_a_photo_outlined,
                                size: 36, color: Colors.teal,
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _isUploadingLogo ? null : _uploadLogo, child: const Text('تغيير الشعار')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_profile != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('رمز المكتب (Office Code)'),
                      subtitle: Text(_profile!.officeCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Tooltip(message: 'يُعدَّل فقط من قبل مالك النظام', child: Icon(Icons.lock_outline, size: 18)),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(controller: _officeNameController, decoration: const InputDecoration(labelText: 'اسم المكتب', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _brokerNameController, decoration: const InputDecoration(labelText: 'اسم المخلص الجمركي', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _licenseNoController, decoration: const InputDecoration(labelText: 'رقم الترخيص', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('حفظ التغييرات'),
                ),
              ],
            ),
    );
  }
}
