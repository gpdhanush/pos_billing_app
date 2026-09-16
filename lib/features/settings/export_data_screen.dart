import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          SoftCard(
            radius: AppRadii.xl,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.18),
                        scheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedDownload04,
                      size: 34,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Export your business data',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Download products, orders, customers, and stock as CSV. Export all packs everything into one ZIP.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Quick export',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          SoftCard(
            radius: AppRadii.lg,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            color: scheme.primary.withValues(alpha: 0.06),
            borderColor: scheme.primary.withValues(alpha: 0.16),
            child: _ExportTile(
              icon: HugeIcons.strokeRoundedFileZip,
              accent: scheme.primary,
              title: 'Export all',
              subtitle: 'ZIP with products, orders, customers & stocks',
              busy: _busy == DataExportKind.all,
              enabled: _busy == null,
              emphasized: true,
              onTap: () => _export(DataExportKind.all),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Individual CSV',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          SoftCard(
            radius: AppRadii.lg,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              children: [
                _ExportTile(
                  icon: HugeIcons.strokeRoundedPackage01,
                  accent: const Color(0xFF2563EB),
                  title: 'Products',
                  subtitle: 'Catalog, prices, and stock qty',
                  busy: _busy == DataExportKind.products,
                  enabled: _busy == null,
                  onTap: () => _export(DataExportKind.products),
                ),
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: scheme.outline.withValues(alpha: 0.35),
                ),
                _ExportTile(
                  icon: HugeIcons.strokeRoundedInvoice01,
                  accent: AppColors.success,
                  title: 'Orders',
                  subtitle: 'Invoices and payments',
                  busy: _busy == DataExportKind.orders,
                  enabled: _busy == null,
                  onTap: () => _export(DataExportKind.orders),
                ),
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: scheme.outline.withValues(alpha: 0.35),
                ),
                _ExportTile(
                  icon: HugeIcons.strokeRoundedUserGroup02,
                  accent: const Color(0xFFD97706),
                  title: 'Customers',
                  subtitle: 'Contacts and balances',
                  busy: _busy == DataExportKind.customers,
                  enabled: _busy == null,
                  onTap: () => _export(DataExportKind.customers),
                ),
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: scheme.outline.withValues(alpha: 0.35),
                ),
                _ExportTile(
                  icon: HugeIcons.strokeRoundedPackage,
                  accent: const Color(0xFF7C3AED),
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
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.busy,
    required this.enabled,
    this.emphasized = false,
  });

  final List<List<dynamic>> icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool busy;
  final bool enabled;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Opacity(
          opacity: enabled || busy ? 1 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: HugeIcon(icon: icon, size: 22, color: accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: accent,
                    ),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: emphasized
                          ? accent.withValues(alpha: 0.14)
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedShare08,
                        size: 18,
                        color: emphasized ? accent : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
