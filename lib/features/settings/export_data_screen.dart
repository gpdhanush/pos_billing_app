import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/services/data_export_service.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

final dataExportServiceProvider = Provider(
  (ref) => DataExportService(ref.watch(databaseProvider)),
);

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  DataExportKind? _busy;

  Future<void> _export(DataExportKind kind) async {
    if (_busy != null) return;
    final store = ref.read(storeProfileProvider).valueOrNull;
    if (store == null) {
      showSnack(context, 'Store not found');
      return;
    }
    setState(() => _busy = kind);
    try {
      await ref.read(dataExportServiceProvider).exportAndShare(
            storeId: store.id,
            kind: kind,
          );
    } catch (_) {
      if (mounted) showSnack(context, 'Export failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: 'Export data',
        subtitle: 'Share reports & CSV files',
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          SoftCard(
            color: scheme.primary.withValues(alpha: 0.06),
            borderColor: scheme.primary.withValues(alpha: 0.14),
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.file_download_outlined,
                  background: scheme.primary.withValues(alpha: 0.12),
                  foreground: scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Export products, orders, customers, and stock movements as CSV. Export all creates a ZIP file.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ExportTile(
                  icon: Icons.archive_outlined,
                  iconColor: scheme.primary,
                  title: 'Export all',
                  subtitle: 'ZIP with products, orders, customers, stocks',
                  busy: _busy == DataExportKind.all,
                  enabled: _busy == null,
                  onTap: () => _export(DataExportKind.all),
                ),
                const Divider(indent: 68),
                _ExportTile(
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Products',
                  subtitle: 'Catalog, prices, and stock qty',
                  busy: _busy == DataExportKind.products,
                  enabled: _busy == null,
                  onTap: () => _export(DataExportKind.products),
                ),
                const Divider(indent: 68),
                _ExportTile(
                  icon: Icons.receipt_long_outlined,
                  iconColor: const Color(0xFF059669),
                  title: 'Orders',
                  subtitle: 'Invoices and payments',
                  busy: _busy == DataExportKind.orders,
                  enabled: _busy == null,
                  onTap: () => _export(DataExportKind.orders),
                ),
                const Divider(indent: 68),
                _ExportTile(
                  icon: Icons.group_outlined,
                  iconColor: const Color(0xFFD97706),
                  title: 'Customers',
                  subtitle: 'Contacts and balances',
                  busy: _busy == DataExportKind.customers,
                  enabled: _busy == null,
                  onTap: () => _export(DataExportKind.customers),
                ),
                const Divider(indent: 68),
                _ExportTile(
                  icon: Icons.warehouse_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Stocks',
                  subtitle: 'Stock movement ledger',
                  busy: _busy == DataExportKind.stocks,
                  enabled: _busy == null,
                  onTap: () => _export(DataExportKind.stocks),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.busy,
    required this.enabled,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconBadge(
              icon: icon,
              size: 40,
              background: iconColor.withValues(alpha: 0.12),
              foreground: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.ios_share_rounded,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
