import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/trader.dart';
import '../services/trader_service.dart';

Future<Trader?> pickTrader(BuildContext context, ApiClient apiClient) async {
  final traderService = TraderService(apiClient: apiClient);
  final controller = TextEditingController();
  List<Trader> results = [];

  return showModalBottomSheet<Trader>(
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
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
            child: SizedBox(
              height: 420,
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'ابحث عن تاجر', prefixIcon: Icon(Icons.search)),
                    onChanged: search,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: results.isEmpty
                        ? const Center(child: Text('ابدأ الكتابة للبحث'))
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
}
