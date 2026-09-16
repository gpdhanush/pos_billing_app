import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
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
  bool _connected = false;
  String? _connectedName;
  bool _busy = false;

  CompositePrinterService get _printer {
    final svc = ref.read(printerServiceProvider);
    if (svc is CompositePrinterService) {
      svc.use('bluetooth');
      return svc;
    }
    throw StateError('Printer service missing');
  }

  @override
  void initState() {
    super.initState();
    _refreshConnection();
  }

  Future<void> _refreshConnection() async {
    try {
      final ok = await _printer.isConnected;
      if (!mounted) return;
      setState(() => _connected = ok);
    } catch (_) {
      if (!mounted) return;
      setState(() => _connected = false);
    }
  }

  Future<void> _disconnect() async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Disconnect printer?',
      body: _connectedName == null
          ? 'Stop using the current Bluetooth printer?'
          : 'Disconnect "$_connectedName"?',
      icon: Icons.bluetooth_disabled_rounded,
      confirmLabel: l10n.printerDisconnect,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await _printer.disconnect();
      if (!mounted) return;
      setState(() {
        _connected = false;
        _connectedName = null;
      });
      showSnack(context, 'Printer disconnected');
    } catch (_) {
      if (!mounted) return;
      showSnack(context, l10n.errorsPrinter);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final paper =
        ref.watch(appSettingsProvider).valueOrNull?.paperSize ?? '58mm';
    final canPop = context.canPop();
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.printerTitle,
        subtitle: 'Receipt printer settings',
        height: 64,
        leading: canPop
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
      ),
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
          SoftCard(
            color: _connected
                ? AppColors.success.withValues(alpha: 0.08)
                : null,
            borderColor: _connected
                ? AppColors.success.withValues(alpha: 0.3)
                : null,
            child: Row(
              children: [
                Icon(
                  _connected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_disabled_rounded,
                  color: _connected
                      ? AppColors.success
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _connected ? 'Printer connected' : 'No printer connected',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _connected ? AppColors.success : null,
                            ),
                      ),
                      if (_connectedName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _connectedName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!_connected) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _scanning
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      setState(() => _scanning = true);
                      try {
                        _devices = await _printer.scan();
                        setState(() {});
                      } on PrinterException catch (e) {
                        if (!mounted) return;
                        final isPermission = e.message.toLowerCase().contains(
                          'permission',
                        );
                        messenger?.showSnackBar(
                          SnackBar(
                            content: Text(
                              isPermission ? e.message : l10n.errorsPrinter,
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
              child: Text(
                _scanning ? 'Scanning…' : l10n.printerConnect,
              ),
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
                        trailing: const Icon(Icons.link_rounded),
                        onTap: _busy
                            ? null
                            : () async {
                                final messenger =
                                    ScaffoldMessenger.maybeOf(context);
                                setState(() => _busy = true);
                                try {
                                  await _printer.connect(_devices[i]);
                                  if (!mounted) return;
                                  setState(() {
                                    _connected = true;
                                    _connectedName = _devices[i].name;
                                  });
                                  messenger?.showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.commonSuccess),
                                    ),
                                  );
                                } on PrinterException {
                                  if (!mounted) return;
                                  messenger?.showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.errorsPrinter),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _busy = false);
                                  }
                                }
                              },
                      ),
                    ],
                ],
              ),
            ),
          ],
          if (_connected) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      setState(() => _busy = true);
                      try {
                        final store =
                            ref.read(storeProfileProvider).valueOrNull;
                        final bytes = await ref
                            .read(receiptBuilderProvider)
                            .testPage(
                              paperSize: paper,
                              storeName: store?.name ?? 'POS',
                            );
                        await _printer.printBytes(bytes);
                        if (!mounted) return;
                        messenger?.showSnackBar(
                          const SnackBar(content: Text('Test print sent')),
                        );
                      } catch (_) {
                        if (!mounted) return;
                        messenger?.showSnackBar(
                          SnackBar(content: Text(l10n.errorsPrinter)),
                        );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              icon: const Icon(Icons.print_outlined),
              label: Text(l10n.printerTest),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      setState(() => _busy = true);
                      try {
                        final store =
                            ref.read(storeProfileProvider).valueOrNull;
                        if (store == null) return;
                        final last = await ref
                            .read(salesRepositoryProvider)
                            .lastCompletedInvoice(store.id);
                        if (!mounted) return;
                        if (last == null) {
                          messenger?.showSnackBar(
                            const SnackBar(
                              content: Text('No completed bill to reprint'),
                            ),
                          );
                          return;
                        }
                        final ok = await printInvoice(ref, last);
                        if (!mounted) return;
                        messenger?.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Last bill sent to printer'
                                  : l10n.errorsPrinter,
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(l10n.printerLastBill),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _disconnect,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.7)),
              ),
              icon: const Icon(Icons.link_off_rounded),
              label: Text(l10n.printerDisconnect),
            ),
          ],
        ],
      ),
    );
  }
}
