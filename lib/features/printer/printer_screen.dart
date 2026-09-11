import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/core/services/printer_service.dart';
import 'package:pos_billing/features/billing/checkout_screen.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class PrinterScreen extends ConsumerStatefulWidget {
  const PrinterScreen({super.key});

  @override
  ConsumerState<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends ConsumerState<PrinterScreen> {
  List<PrinterDevice> _devices = const [];
  bool _scanning = false;

  CompositePrinterService get _printer {
    final svc = ref.read(printerServiceProvider);
    if (svc is CompositePrinterService) {
      svc.use('bluetooth');
      return svc;
    }
    throw StateError('Printer service missing');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paper =
        ref.watch(appSettingsProvider).valueOrNull?.paperSize ?? '58mm';
    return Scaffold(
      appBar: GlassPageHeader(title: l10n.printerTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.printerPaperSize,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('58mm'),
                      selected: paper == '58mm',
                      onSelected: (_) => ref
                          .read(appSettingsProvider.notifier)
                          .setPaperSize('58mm'),
                    ),
                    ChoiceChip(
                      label: const Text('80mm'),
                      selected: paper == '80mm',
                      onSelected: (_) => ref
                          .read(appSettingsProvider.notifier)
                          .setPaperSize('80mm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _scanning
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    setState(() => _scanning = true);
                    try {
                      _devices = await _printer.scan();
                    } on PrinterException catch (e) {
                      if (!mounted) return;
                      final isPermission = e.message.toLowerCase().contains(
                        'permission',
                      );
                      messenger?.showSnackBar(
                        SnackBar(
                          content: Text(
                            isPermission
                                ? e.message
                                : l10n.errorsPrinter,
                          ),
                          action: isPermission
                              ? SnackBarAction(
                                  label: 'Allow',
                                  onPressed: () =>
                                      context.push('/permissions'),
                                )
                              : null,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _scanning = false);
                    }
                  },
            child: Text(l10n.printerConnect),
          ),
          const SizedBox(height: 12),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (_devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.printerNone),
                  )
                else
                  for (var i = 0; i < _devices.length; i++) ...[
                    if (i > 0) const Divider(),
                    ListTile(
                      leading: const IconBadge(icon: Icons.print_outlined),
                      title: Text(_devices[i].name),
                      subtitle: Text(_devices[i].address),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        try {
                          await _printer.connect(_devices[i]);
                          if (!mounted) return;
                          messenger?.showSnackBar(
                            SnackBar(content: Text(l10n.commonSuccess)),
                          );
                        } on PrinterException {
                          if (!mounted) return;
                          messenger?.showSnackBar(
                            SnackBar(content: Text(l10n.errorsPrinter)),
                          );
                        }
                      },
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              try {
                final store = ref.read(storeProfileProvider).valueOrNull;
                final bytes = await ref
                    .read(receiptBuilderProvider)
                    .testPage(
                      paperSize: paper,
                      storeName: store?.name ?? 'POS',
                    );
                await _printer.printBytes(bytes);
              } catch (_) {
                if (!mounted) return;
                messenger?.showSnackBar(
                  SnackBar(content: Text(l10n.errorsPrinter)),
                );
              }
            },
            child: Text(l10n.printerTest),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              final store = ref.read(storeProfileProvider).valueOrNull;
              if (store == null) return;
              final last = await ref
                  .read(salesRepositoryProvider)
                  .lastCompletedInvoice(store.id);
              if (last == null) return;
              final ok = await printInvoice(ref, last);
              if (!mounted) return;
              if (!ok) {
                messenger?.showSnackBar(
                  SnackBar(content: Text(l10n.errorsPrinter)),
                );
              }
            },
            child: Text(l10n.printerLastBill),
          ),
          TextButton(
            onPressed: () => _printer.disconnect(),
            child: Text(l10n.printerDisconnect),
          ),
        ],
      ),
    );
  }
}
