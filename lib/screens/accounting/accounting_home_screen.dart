import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/accounting.dart';
import '../../services/accounting_service.dart';
import 'cash_boxes_screen.dart';
import 'vouchers_screen.dart';
import 'expenses_screen.dart';
import 'service_invoices_screen.dart';
import 'trader_statement_screen.dart';
import 'profit_loss_screen.dart';

class AccountingHomeScreen extends StatefulWidget {
  const AccountingHomeScreen({super.key});

  @override
  State<AccountingHomeScreen> createState() => _AccountingHomeScreenState();
}

class _AccountingHomeScreenState extends State<AccountingHomeScreen> {
  List<CashBox> _cashBoxes = [];
  bool _isLoading = true;
  String? _error;

  late final AccountingService _service = AccountingService(apiClient: context.read<ApiClient>());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final boxes = await _service.listCashBoxes();
      setState(() => _cashBoxes = boxes);
    } on ApiException catch (e) {
      setState(() => _error = e.displayMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحاسبة')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('أرصدة الصناديق', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_cashBoxes.isEmpty)
              const Text('لا يوجد صندوق بعد. أنشئ صندوقاً من "الصناديق" أدناه.', style: TextStyle(color: Colors.grey))
            else
              ..._cashBoxes.map((box) => Card(
                    child: ListTile(
                      leading: Icon(box.type == 'bank' ? Icons.account_balance_outlined : Icons.payments_outlined),
                      title: Text(box.name),
                      subtitle: Text(box.typeLabel),
                      trailing: Text(box.balance.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )),
            const SizedBox(height: 24),
            _MenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'الصناديق',
              subtitle: 'إدارة الصناديق النقدية والبنكية وإغلاق اليوم',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CashBoxesScreen())).then((_) => _load()),
            ),
            _MenuTile(
              icon: Icons.receipt_long_outlined,
              title: 'السندات',
              subtitle: 'سندات القبض والصرف',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VouchersScreen())).then((_) => _load()),
            ),
            _MenuTile(
              icon: Icons.money_off_outlined,
              title: 'المصروفات',
              subtitle: 'تسجيل مصروفات المكتب',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpensesScreen())),
            ),
            _MenuTile(
              icon: Icons.request_quote_outlined,
              title: 'فواتير الأتعاب',
              subtitle: 'أتعاب التخليص على التجار',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServiceInvoicesScreen())),
            ),
            _MenuTile(
              icon: Icons.summarize_outlined,
              title: 'كشف حساب تاجر',
              subtitle: 'كشف تفصيلي بالرصيد المتراكم',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TraderStatementScreen())),
            ),
            _MenuTile(
              icon: Icons.pie_chart_outline,
              title: 'الأرباح والخسائر',
              subtitle: 'تقرير مالي حسب الفترة',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfitLossScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
