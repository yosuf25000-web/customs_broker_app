import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/accounting.dart';
import '../../services/accounting_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late final AccountingService _service = AccountingService(apiClient: context.read<ApiClient>());
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.listExpenses();
      if (mounted) setState(() => _expenses = items);
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
      builder: (context) => _ExpenseForm(service: _service),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المصروفات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? const Center(child: Text('لا توجد مصروفات مسجّلة بعد'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final e = _expenses[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.money_off_outlined, color: Colors.red),
                          title: Text('${e.expenseNo} — ${e.amount.toStringAsFixed(2)}'),
                          subtitle: Text('${e.categoryName ?? ''}${e.description != null ? ' • ${e.description}' : ''}'),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add),
        label: const Text('مصروف جديد'),
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  final AccountingService service;
  const _ExpenseForm({required this.service});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  List<AccountingCategory> _categories = [];
  List<CashBox> _cashBoxes = [];
  AccountingCategory? _selectedCategory;
  CashBox? _selectedCashBox;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newCategoryController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final categories = await widget.service.listExpenseCategories();
    final boxes = await widget.service.listCashBoxes();
    if (mounted) setState(() { _categories = categories; _cashBoxes = boxes; });
  }

  Future<void> _addCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;
    try {
      final category = await widget.service.createExpenseCategory(name);
      _newCategoryController.clear();
      if (mounted) setState(() { _categories.add(category); _selectedCategory = category; });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red));
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (_selectedCategory == null || _selectedCashBox == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أكمل كل الحقول المطلوبة')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.service.createExpense(
        categoryId: _selectedCategory!.id,
        amount: amount,
        cashBoxId: _selectedCashBox!.id,
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
            Text('مصروف جديد', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccountingCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'تصنيف المصروف', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (c) => setState(() => _selectedCategory = c),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(hintText: 'أو أضف تصنيفاً جديداً'),
                  ),
                ),
                TextButton(onPressed: _addCategory, child: const Text('إضافة')),
              ],
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
                  : const Text('حفظ المصروف'),
            ),
          ],
        ),
      ),
    );
  }
}
