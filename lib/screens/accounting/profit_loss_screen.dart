import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../services/accounting_service.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  late final AccountingService _service = AccountingService(apiClient: context.read<ApiClient>());
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  Map<String, dynamic>? _report;
  bool _isLoading = false;
  String? _error;

  String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range != null) {
      setState(() { _from = range.start; _to = range.end; });
      _load();
    }
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final report = await _service.profitLossReport(from: _fmt(_from), to: _fmt(_to));
      setState(() => _report = report);
    } on ApiException catch (e) {
      setState(() => _error = e.displayMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final revenue = (_report?['revenue'] as List<dynamic>?) ?? [];
    final expenses = (_report?['expenses'] as List<dynamic>?) ?? [];
    final netProfit = _report?['net_profit'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرباح والخسائر'),
        actions: [IconButton(icon: const Icon(Icons.date_range_outlined), onPressed: _pickRange)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('الفترة: ${_fmt(_from)} إلى ${_fmt(_to)}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Card(
                      color: (netProfit != null && double.parse('$netProfit') >= 0) ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text('صافي الربح/الخسارة', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text(
                              '${netProfit ?? '0.00'}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('الإيرادات (${_report?['total_revenue'] ?? 0})', style: Theme.of(context).textTheme.titleMedium),
                    ...revenue.map((r) => ListTile(
                          dense: true,
                          title: Text(r['name'] ?? ''),
                          trailing: Text('${r['total']}', style: const TextStyle(color: Colors.green)),
                        )),
                    const Divider(height: 32),
                    Text('المصروفات (${_report?['total_expenses'] ?? 0})', style: Theme.of(context).textTheme.titleMedium),
                    ...expenses.map((e) => ListTile(
                          dense: true,
                          title: Text(e['name'] ?? ''),
                          trailing: Text('${e['total']}', style: const TextStyle(color: Colors.red)),
                        )),
                  ],
                ),
    );
  }
}
