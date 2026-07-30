import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/traders_provider.dart';
import '../../widgets/error_banner.dart';
import 'trader_form_screen.dart';

class TradersListScreen extends StatefulWidget {
  const TradersListScreen({super.key});

  @override
  State<TradersListScreen> createState() => _TradersListScreenState();
}

class _TradersListScreenState extends State<TradersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradersProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TradersProvider>();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو السجل التجاري أو الرقم الضريبي',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => provider.load(query: value),
            ),
          ),
          if (provider.errorMessage != null)
            ErrorBanner(message: provider.errorMessage!, onRetry: () => provider.load()),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.traders.isEmpty
                    ? const Center(child: Text('لا يوجد تجار بعد'))
                    : RefreshIndicator(
                        onRefresh: () => provider.load(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: provider.traders.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final trader = provider.traders[index];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
                              title: Text(trader.name),
                              subtitle: Text(trader.phone ?? trader.commercialRegister ?? ''),
                              trailing: Text('${trader.currentBalance.toStringAsFixed(2)}'),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const TraderFormScreen()),
          );
          if (created == true && context.mounted) {
            context.read<TradersProvider>().load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('تاجر جديد'),
      ),
    );
  }
}
