import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/trader.dart';
import '../../services/declaration_service.dart';
import '../../services/trader_service.dart';

class DeclarationFormScreen extends StatefulWidget {
  const DeclarationFormScreen({super.key});

  @override
  State<DeclarationFormScreen> createState() => _DeclarationFormScreenState();
}

class _DeclarationFormScreenState extends State<DeclarationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Trader? _selectedTrader;
  final _invoiceNoController = TextEditingController();
  final _invoiceValueController = TextEditingController(text: '0');
  final _freightController = TextEditingController(text: '0');
  final _insuranceController = TextEditingController(text: '0');
  final _otherExpensesController = TextEditingController(text: '0');
  String _currencyCode = 'USD';
  bool _isSaving = false;

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _invoiceValueController.dispose();
    _freightController.dispose();
    _insuranceController.dispose();
    _otherExpensesController.dispose();
    super.dispose();
  }

  Future<void> _pickTrader() async {
    final apiClient = context.read<ApiClient>();
    final traderService = TraderService(apiClient: apiClient);
    final controller = TextEditingController();
    List<Trader> results = [];

    final selected = await showModalBottomSheet<Trader>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> search(String query) async {
              try {
                final r = await traderService.list(query: query);
                setModalState(() => results = r);
              } catch (_) {
                // تجاهل أخطاء البحث المؤقتة أثناء الكتابة
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'ابحث عن تاجر بالاسم أو السجل التجاري',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: search,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: results.isEmpty
                          ? const Center(child: Text('ابدأ الكتابة للبحث عن تاجر'))
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final trader = results[index];
                                return ListTile(
                                  title: Text(trader.name),
                                  subtitle: Text(trader.commercialRegister ?? ''),
                                  onTap: () => Navigator.of(context).pop(trader),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedTrader = selected);
    }
  }

  Future<void> _submit() async {
    if (_selectedTrader == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار التاجر/المستورد')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final apiClient = context.read<ApiClient>();
      final service = DeclarationService(apiClient: apiClient);
      await service.create(
        traderId: _selectedTrader!.id,
        invoiceNo: _invoiceNoController.text.trim().isEmpty ? null : _invoiceNoController.text.trim(),
        currencyCode: _currencyCode,
        invoiceValue: double.tryParse(_invoiceValueController.text) ?? 0,
        freightValue: double.tryParse(_freightController.text) ?? 0,
        insuranceValue: double.tryParse(_insuranceController.text) ?? 0,
        otherExpenses: double.tryParse(_otherExpensesController.text) ?? 0,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إقرار جمركي جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(_selectedTrader?.name ?? 'اختر التاجر/المستورد'),
                subtitle: _selectedTrader != null ? Text(_selectedTrader!.commercialRegister ?? '') : null,
                trailing: const Icon(Icons.chevron_left),
                onTap: _pickTrader,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _invoiceNoController,
              decoration: const InputDecoration(labelText: 'رقم الفاتورة التجارية', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currencyCode,
              decoration: const InputDecoration(labelText: 'العملة', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                DropdownMenuItem(value: 'YER', child: Text('ريال يمني (YER)')),
                DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
              ],
              onChanged: (value) => setState(() => _currencyCode = value ?? 'USD'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _invoiceValueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'قيمة الفاتورة', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _freightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'قيمة الشحن', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _insuranceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'قيمة التأمين', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otherExpensesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'مصاريف أخرى', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ كمسودة'),
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك إضافة الأصناف وتشغيل الحساب واعتماد الإقرار من شاشة التفاصيل بعد الحفظ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
