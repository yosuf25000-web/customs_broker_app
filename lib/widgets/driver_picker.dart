import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/accounting.dart';
import '../services/accounting_service.dart';

Future<Driver?> pickDriver(BuildContext context, ApiClient apiClient) async {
  final service = AccountingService(apiClient: apiClient);
  List<Driver> drivers = [];
  try {
    drivers = await service.listDrivers();
  } catch (_) {
    // سنعرض قائمة فارغة مع رسالة إن فشل التحميل
  }

  if (!context.mounted) return null;

  return showModalBottomSheet<Driver>(
    context: context,
    builder: (context) => SafeArea(
      child: drivers.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text('لا يوجد سائقون مسجّلون بعد. أضف سائقاً أولاً من شاشة المحاسبة.', textAlign: TextAlign.center),
            )
          : ListView(
              shrinkWrap: true,
              children: drivers
                  .map((d) => ListTile(
                        title: Text(d.name),
                        subtitle: Text(d.phone ?? ''),
                        onTap: () => Navigator.of(context).pop(d),
                      ))
                  .toList(),
            ),
    ),
  );
}
