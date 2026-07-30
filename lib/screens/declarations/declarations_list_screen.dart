import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/declaration.dart';
import '../../providers/declarations_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_badge.dart';
import 'declaration_detail_screen.dart';
import 'declaration_form_screen.dart';

class DeclarationsListScreen extends StatefulWidget {
  const DeclarationsListScreen({super.key});

  @override
  State<DeclarationsListScreen> createState() => _DeclarationsListScreenState();
}

class _DeclarationsListScreenState extends State<DeclarationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeclarationsProvider>().load();
    });
  }

  final _statusFilters = const [
    {'value': null, 'label': 'الكل'},
    {'value': 'draft', 'label': 'مسودة'},
    {'value': 'calculated', 'label': 'تم الحساب'},
    {'value': 'approved', 'label': 'معتمد'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeclarationsProvider>();

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final selected = provider.statusFilter == filter['value'];
                return ChoiceChip(
                  label: Text(filter['label'] as String),
                  selected: selected,
                  onSelected: (_) => provider.load(status: filter['value'] as String?),
                );
              },
            ),
          ),
          if (provider.errorMessage != null)
            ErrorBanner(message: provider.errorMessage!, onRetry: () => provider.refresh()),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.declarations.isEmpty
                    ? const Center(child: Text('لا توجد إقرارات بعد'))
                    : RefreshIndicator(
                        onRefresh: provider.refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: provider.declarations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final decl = provider.declarations[index];
                            return _DeclarationCard(declaration: decl);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const DeclarationFormScreen()),
          );
          if (created == true && context.mounted) {
            context.read<DeclarationsProvider>().refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('إقرار جديد'),
      ),
    );
  }
}

class _DeclarationCard extends StatelessWidget {
  final Declaration declaration;
  const _DeclarationCard({required this.declaration});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DeclarationDetailScreen(declarationId: declaration.id)),
          );
          if (context.mounted) context.read<DeclarationsProvider>().refresh();
        },
        title: Text(declaration.internalNo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(declaration.traderName ?? ''),
        trailing: StatusBadge(status: declaration.status, label: declaration.statusLabel),
      ),
    );
  }
}
