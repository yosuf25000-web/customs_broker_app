import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/declaration_item.dart';
import '../../models/tariff_code_suggestion.dart';
import '../../services/tariff_service.dart';

/// نافذة سفلية لإضافة صنف جديد. البحث في التعرفة اقتراحي فقط —
/// المخلص الجمركي هو من يختار البند نهائياً (لا اعتماد تلقائي).
Future<DeclarationItem?> showAddItemSheet(BuildContext context, {required ApiClient apiClient}) {
  return showModalBottomSheet<DeclarationItem>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AddItemForm(apiClient: apiClient),
  );
}

class _AddItemForm extends StatefulWidget {
  final ApiClient apiClient;
  const _AddItemForm({required this.apiClient});

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'قطعة');
  final _netWeightController = TextEditingController();
  final _grossWeightController = TextEditingController();
  final _valueController = TextEditingController(text: '0');
  final _tariffSearchController = TextEditingController();

  TariffCodeSuggestion? _selectedTariff;
  List<TariffCodeSuggestion> _suggestions = [];
  bool _searching = false;

  late final TariffService _tariffService = TariffService(apiClient: widget.apiClient);

  Future<void> _searchTariff(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await _tariffService.search(query);
      if (mounted) setState(() => _suggestions = results);
    } on ApiException {
      // تجاهل أخطاء البحث المؤقتة أثناء الكتابة
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final item = DeclarationItem(
      id: '', // يُولَّد من الخادم عند الحفظ
      tariffCodeId: _selectedTariff?.id,
      goodsDescription: _descriptionController.text.trim(),
      quantity: double.tryParse(_quantityController.text) ?? 0,
      unit: _unitController.text.trim(),
      netWeight: double.tryParse(_netWeightController.text),
      grossWeight: double.tryParse(_grossWeightController.text),
      itemValue: double.tryParse(_valueController.text) ?? 0,
    );
    Navigator.of(context).pop(item);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _netWeightController.dispose();
    _grossWeightController.dispose();
    _valueController.dispose();
    _tariffSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إضافة صنف جديد', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              TextField(
                controller: _tariffSearchController,
                decoration: InputDecoration(
                  labelText: 'ابحث عن البند الجمركي (HS Code أو الوصف)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searching ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ) : null,
                ),
                onChanged: _searchTariff,
              ),
              if (_suggestions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final s = _suggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(s.hsCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          setState(() {
                            _selectedTariff = s;
                            _suggestions = [];
                            _tariffSearchController.text = '${s.hsCode} — ${s.description}';
                            if (_descriptionController.text.isEmpty) {
                              _descriptionController.text = s.description;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              if (_selectedTariff != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Chip(
                    label: Text('البند المختار: ${_selectedTariff!.hsCode}'),
                    onDeleted: () => setState(() => _selectedTariff = null),
                  ),
                ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'وصف البضاعة', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'الوحدة', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _netWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'الوزن الصافي (كجم)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _grossWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'الوزن القائم (كجم)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'قيمة الصنف', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('إضافة الصنف'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
