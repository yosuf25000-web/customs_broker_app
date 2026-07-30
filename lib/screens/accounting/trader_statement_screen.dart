import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/accounting.dart';
import '../../models/trader.dart';
import '../../services/accounting_service.dart';
import '../../widgets/trader_picker.dart';

class TraderStatementScreen extends StatefulWidget {
  const TraderStatementScreen({super.key});

  @override
  State<TraderStatementScreen> createState() => _TraderStatementScreenState();
}

class _TraderStatementScreenState extends State<TraderStatementScreen> {
  late final AccountingService _service = AccountingService(apiClient: context.read<ApiClient>());
  Trader? _trader;
  List<StatementLine> _lines = [];
  double _closingBalance = 0;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickTraderAndLoad() async {
    final t = await pickTrader(context, context.read<ApiClient>());
    if (t == null) return;
    setState(() { _trader = t; _isLoading = true; _error = null; });
    try {
      final result = await _service.traderStatement(t.id);
      setState(() { _lines = result.lines; _closingBalance = result.closingBalance; });
    } on ApiException catch (e) {
      setState(() => _error = e.displayMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime d) {
    final iso = d.toIso8601String();
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كشف حساب تاجر')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(_trader?.name ?? 'اختر التاجر لعرض كشف حسابه'),
                trailing: const Icon(Icons.chevron_left),
                onTap: _pickTraderAndLoad,
              ),
            ),
          ),
          if (_trader != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الرصيد الحالي', style: TextStyle(color: Colors.grey)),
                  Text(
                    _closingBalance.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18,
                      color: _closingBalance > 0 ? Colors.red : Colors.green, // موجب = مدين للمكتب
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _lines.isEmpty
                        ? Center(child: Text(_trader == null ? '' : 'لا توجد حركات على هذا الحساب بعد'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _lines.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final line = _lines[index];
                              return ListTile(
                                dense: true,
                                title: Text(line.description ?? line.entryNo),
                                subtitle: Text('${_formatDate(line.entryDate)} • ${line.entryNo}'),
                                trailing: Text(
                                  line.debit > 0 ? '+${line.debit.toStringAsFixed(2)}' : '-${line.credit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: line.debit > 0 ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
