import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/accounting.dart';
import '../../services/accounting_service.dart';

class CashBoxesScreen extends StatefulWidget {
  const CashBoxesScreen({super.key});

  @override
  State<CashBoxesScreen> createState() => _CashBoxesScreenState();
}

class _CashBoxesScreenState extends State<CashBoxesScreen> {
  late final AccountingService _service = AccountingService(apiClient: context.read<ApiClient>());
  List<CashBox> _boxes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final boxes = await _service.listCashBoxes();
      if (mounted) setState(() => _boxes = boxes);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createCashBox() async {
    final nameController = TextEditingController();
    String type = 'cash';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('صندوق جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الصندوق')),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', label: Text('نقدي')),
                  ButtonSegment(value: 'bank', label: Text('بنكي')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setDialogState(() => type = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إنشاء')),
          ],
        ),
      ),
    );
    if (result != true || nameController.text.trim().isEmpty) return;

    try {
      await _service.createCashBox(name: nameController.text.trim(), type: type);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    }
  }

  Future<void> _closeDay(CashBox box) async {
    final controller = TextEditingController();
    final notesController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إغلاق صندوق: ${box.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الرصيد المتوقع حسب النظام: ${box.balance.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الرصيد الفعلي بعد العدّ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد الإغلاق')),
        ],
      ),
    );
    if (result != true) return;
    final actual = double.tryParse(controller.text);
    if (actual == null) return;

    try {
      final closing = await _service.closeCashBoxDay(cashBoxId: box.id, actualCountedBalance: actual, notes: notesController.text.trim());
      if (mounted) {
        final diff = closing['difference'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الإغلاق. الفرق: $diff')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصناديق')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _boxes.map((box) => Card(
                      child: ListTile(
                        leading: Icon(box.type == 'bank' ? Icons.account_balance_outlined : Icons.payments_outlined),
                        title: Text(box.name),
                        subtitle: Text('${box.typeLabel} — الرصيد: ${box.balance.toStringAsFixed(2)}'),
                        trailing: OutlinedButton(onPressed: () => _closeDay(box), child: const Text('إغلاق اليوم')),
                      ),
                    )).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCashBox,
        icon: const Icon(Icons.add),
        label: const Text('صندوق جديد'),
      ),
    );
  }
}
