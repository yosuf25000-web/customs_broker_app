import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/accounting.dart';
import '../../models/trader.dart';
import '../../services/accounting_service.dart';
import '../../widgets/trader_picker.dart';

class ServiceInvoicesScreen extends StatefulWidget {
  const ServiceInvoicesScreen({super.key});

  @override
  State<ServiceInvoicesScreen> createState() => _ServiceInvoicesScreenState();
}

class _ServiceInvoicesScreenState extends State<ServiceInvoicesScreen> {
  late final AccountingService _service = AccountingService(apiClient: context.read<ApiClient>());
  List<ServiceInvoice> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.listServiceInvoices();
      if (mounted) setState(() => _invoices = items);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ServiceInvoiceForm(apiClient: context.read<ApiClient>(), service: _service),
    );
    if (created == true) _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partially_paid':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فواتير أتعاب التخليص')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(child: Text('لا توجد فواتير أتعاب بعد'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final inv = _invoices[index];
                      return Card(
                        child: ListTile(
                          title: Text('${inv.invoiceNo} — ${inv.amount.toStringAsFixed(2)}'),
                          subtitle: Text(inv.traderName ?? ''),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(inv.status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(inv.statusLabel, style: TextStyle(color: _statusColor(inv.status), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add),
        label: const Text('فاتورة جديدة'),
      ),
    );
  }
}

class _ServiceInvoiceForm extends StatefulWidget {
  final ApiClient apiClient;
  final AccountingService service;
  const _ServiceInvoiceForm({required this.apiClient, required this.service});

  @override
  State<_ServiceInvoiceForm> createState() => _ServiceInvoiceFormState();
}

class _ServiceInvoiceFormState extends State<_ServiceInvoiceForm> {
  Trader? _selectedTrader;
  AccountingCategory? _selectedCategory;
  List<AccountingCategory> _categories = [];
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newCategoryController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    widget.service.listRevenueCategories().then((cats) {
      if (mounted) setState(() => _categories = cats);
    });
  }

  Future<void> _addCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;
    try {
      final category = await widget.service.createRevenueCategory(name);
      _newCategoryController.clear();
      if (mounted) setState(() { _categories.add(category); _selectedCategory = category; });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (_selectedTrader == null || _selectedCategory == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أكمل كل الحقول المطلوبة')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.service.createServiceInvoice(
        traderId: _selectedTrader!.id,
        revenueCategoryId: _selectedCategory!.id,
        amount: amount,
        description: _descriptionController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('فاتورة أتعاب تخليص جديدة', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text(_selectedTrader?.name ?? 'اختر التاجر'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () async {
                  final t = await pickTrader(context, widget.apiClient);
                  if (t != null) setState(() => _selectedTrader = t);
                },
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountingCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'تصنيف الإيراد', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (c) => setState(() => _selectedCategory = c),
            ),
            Row(
              children: [
                Expanded(child: TextField(controller: _newCategoryController, decoration: const InputDecoration(hintText: 'أو أضف تصنيفاً جديداً'))),
                TextButton(onPressed: _addCategory, child: const Text('إضافة')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'الوصف (اختياري)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ الفاتورة'),
            ),
          ],
        ),
      ),
    );
  }
}
