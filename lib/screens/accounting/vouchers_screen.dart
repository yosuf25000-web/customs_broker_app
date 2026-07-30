import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/accounting.dart';
import '../../models/trader.dart';
import '../../services/accounting_service.dart';
import '../../widgets/trader_picker.dart';
import '../../widgets/driver_picker.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  late final AccountingService _service = AccountingService(apiClient: context.read<ApiClient>());
  List<Voucher> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final vouchers = await _service.listVouchers();
      if (mounted) setState(() => _vouchers = vouchers);
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
      builder: (context) => _VoucherForm(apiClient: context.read<ApiClient>(), service: _service),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('السندات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vouchers.isEmpty
              ? const Center(child: Text('لا توجد سندات بعد'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _vouchers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final v = _vouchers[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            v.isReceipt ? Icons.south_west : Icons.north_east,
                            color: v.isReceipt ? Colors.green : Colors.red,
                          ),
                          title: Text('${v.voucherNo} — ${v.amount.toStringAsFixed(2)}'),
                          subtitle: Text(v.description ?? (v.isReceipt ? 'سند قبض' : 'سند صرف')),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add),
        label: const Text('سند جديد'),
      ),
    );
  }
}

class _VoucherForm extends StatefulWidget {
  final ApiClient apiClient;
  final AccountingService service;
  const _VoucherForm({required this.apiClient, required this.service});

  @override
  State<_VoucherForm> createState() => _VoucherFormState();
}

class _VoucherFormState extends State<_VoucherForm> {
  String _type = 'receipt';
  String _partyType = 'trader';
  Trader? _selectedTrader;
  Driver? _selectedDriver;
  CashBox? _selectedCashBox;
  List<CashBox> _cashBoxes = [];
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    widget.service.listCashBoxes().then((boxes) {
      if (mounted) setState(() => _cashBoxes = boxes);
    });
  }

  Future<void> _submit() async {
    final partyId = _partyType == 'trader' ? _selectedTrader?.id : _selectedDriver?.id;
    final amount = double.tryParse(_amountController.text);

    if (partyId == null || amount == null || amount <= 0 || _selectedCashBox == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أكمل كل الحقول المطلوبة')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.service.createVoucher(
        type: _type,
        partyType: _partyType,
        partyId: partyId,
        cashBoxId: _selectedCashBox!.id,
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
            Text('سند جديد', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'receipt', label: Text('قبض')),
                ButtonSegment(value: 'payment', label: Text('صرف')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'trader', label: Text('تاجر')),
                ButtonSegment(value: 'driver', label: Text('سائق')),
              ],
              selected: {_partyType},
              onSelectionChanged: (s) => setState(() {
                _partyType = s.first;
                _selectedTrader = null;
                _selectedDriver = null;
              }),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(_partyType == 'trader' ? (_selectedTrader?.name ?? 'اختر التاجر') : (_selectedDriver?.name ?? 'اختر السائق')),
                trailing: const Icon(Icons.chevron_left),
                onTap: () async {
                  if (_partyType == 'trader') {
                    final t = await pickTrader(context, widget.apiClient);
                    if (t != null) setState(() => _selectedTrader = t);
                  } else {
                    final d = await pickDriver(context, widget.apiClient);
                    if (d != null) setState(() => _selectedDriver = d);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CashBox>(
              value: _selectedCashBox,
              decoration: const InputDecoration(labelText: 'الصندوق', border: OutlineInputBorder()),
              items: _cashBoxes.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
              onChanged: (b) => setState(() => _selectedCashBox = b),
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
                  : const Text('حفظ السند'),
            ),
          ],
        ),
      ),
    );
  }
}
