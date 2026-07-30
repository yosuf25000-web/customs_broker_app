import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/declaration.dart';
import '../../services/declaration_service.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/documents_section.dart';
import 'add_item_sheet.dart';

class DeclarationDetailScreen extends StatefulWidget {
  final String declarationId;
  const DeclarationDetailScreen({super.key, required this.declarationId});

  @override
  State<DeclarationDetailScreen> createState() => _DeclarationDetailScreenState();
}

class _DeclarationDetailScreenState extends State<DeclarationDetailScreen> {
  Declaration? _declaration;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;
  Map<String, dynamic>? _lastCalculationTotals;

  late final DeclarationService _service = DeclarationService(apiClient: context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final decl = await _service.getById(widget.declarationId);
      setState(() => _declaration = decl);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.displayMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem() async {
    final item = await showAddItemSheet(context, apiClient: context.read<ApiClient>());
    if (item == null) return;
    setState(() => _isBusy = true);
    try {
      await _service.addItem(widget.declarationId, item);
      await _load();
    } on ApiException catch (e) {
      _showError(e);
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteItem(String itemId) async {
    setState(() => _isBusy = true);
    try {
      await _service.deleteItem(widget.declarationId, itemId);
      await _load();
    } on ApiException catch (e) {
      _showError(e);
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _calculate() async {
    setState(() => _isBusy = true);
    try {
      final result = await _service.calculate(widget.declarationId);
      setState(() => _lastCalculationTotals = result.totals);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تشغيل الحساب بنجاح. راجع الإجماليات قبل الاعتماد.')),
        );
      }
    } on ApiException catch (e) {
      _showError(e);
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاعتماد'),
        content: const Text('بعد الاعتماد لن يمكن تعديل الإقرار مباشرة إلا عبر إعادة الفتح بصلاحية خاصة. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('اعتماد')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await _service.approve(widget.declarationId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم اعتماد الإقرار بنجاح.')));
      }
    } on ApiException catch (e) {
      if (e.code == 'STALE_CALCULATION') {
        _showError(e);
        await _load();
      } else {
        _showError(e);
      }
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _reopen() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة فتح الإقرار'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'سبب إعادة الفتح (إلزامي)', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      await _service.reopen(widget.declarationId, reason);
      await _load();
    } on ApiException catch (e) {
      _showError(e);
    } finally {
      setState(() => _isBusy = false);
    }
  }

  void _showError(ApiException e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.displayMessage), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decl = _declaration;
    return Scaffold(
      appBar: AppBar(title: Text(decl?.internalNo ?? 'تفاصيل الإقرار')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? ErrorBanner(message: _errorMessage!, onRetry: _load)
              : decl == null
                  ? const SizedBox()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(decl.traderName ?? '', style: Theme.of(context).textTheme.titleMedium),
                              StatusBadge(status: decl.status, label: decl.statusLabel),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(label: 'رقم الفاتورة', value: decl.invoiceNo ?? '—'),
                          _InfoRow(label: 'القيمة الجمركية', value: '${decl.customsValue.toStringAsFixed(2)} ${decl.currencyCode}'),
                          if (_lastCalculationTotals != null) ...[
                            const Divider(height: 32),
                            Text('نتيجة آخر حساب', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            _InfoRow(label: 'إجمالي الرسوم الجمركية', value: '${_lastCalculationTotals!['total_duty']}'),
                            _InfoRow(label: 'إجمالي الضرائب', value: '${_lastCalculationTotals!['total_tax']}'),
                            _InfoRow(label: 'رسوم أخرى', value: '${_lastCalculationTotals!['total_fees']}'),
                            _InfoRow(label: 'الإعفاءات', value: '${_lastCalculationTotals!['total_exemptions']}'),
                            _InfoRow(
                              label: 'الإجمالي المستحق',
                              value: '${_lastCalculationTotals!['grand_total_due']}',
                              bold: true,
                            ),
                          ],
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الأصناف (${decl.items.length})', style: Theme.of(context).textTheme.titleSmall),
                              if (decl.status != DeclarationStatus.approved)
                                TextButton.icon(
                                  onPressed: _isBusy ? null : _addItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text('إضافة صنف'),
                                ),
                            ],
                          ),
                          ...decl.items.map((item) => Card(
                                child: ListTile(
                                  title: Text(item.goodsDescription),
                                  subtitle: Text([
                                    if (item.hsCode != null) 'البند: ${item.hsCode}',
                                    'الكمية: ${item.quantity} ${item.unit ?? ''}',
                                    if (item.totalItemFees != null) 'الرسوم: ${item.totalItemFees}',
                                  ].join(' • ')),
                                  trailing: decl.status != DeclarationStatus.approved
                                      ? IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: _isBusy ? null : () => _deleteItem(item.id),
                                        )
                                      : null,
                                  isThreeLine: item.warning != null,
                                ),
                              )),
                          const Divider(height: 32),
                          DocumentsSection(
                            relatedType: 'declaration',
                            relatedId: widget.declarationId,
                            apiClient: context.read<ApiClient>(),
                            readOnly: decl.status == DeclarationStatus.approved,
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
      bottomNavigationBar: decl == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildActionButton(decl),
              ),
            ),
    );
  }

  Widget _buildActionButton(Declaration decl) {
    if (_isBusy) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (decl.status) {
      case DeclarationStatus.draft:
        return FilledButton.icon(
          onPressed: decl.items.isEmpty ? null : _calculate,
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('تشغيل الحساب'),
        );
      case DeclarationStatus.calculated:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة الحساب'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _approve,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('اعتماد الإقرار'),
              ),
            ),
          ],
        );
      case DeclarationStatus.approved:
        return OutlinedButton.icon(
          onPressed: _reopen,
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('إعادة فتح الإقرار (Amendment)'),
        );
      default:
        return const SizedBox();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
