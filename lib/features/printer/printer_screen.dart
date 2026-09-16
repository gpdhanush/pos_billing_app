import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
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
  bool _hasScanned = false;

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

  Future<void> _scan() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _scanning = true);
    try {
      final found = await _printer.scan();
      if (!mounted) return;
      setState(() {
        _devices = found;
        _hasScanned = true;
      });
    } on PrinterException catch (e) {
      if (!mounted) return;
      final isPermission = e.message.toLowerCase().contains('permission');
      messenger?.showSnackBar(
        SnackBar(
          content: Text(isPermission ? e.message : l10n.errorsPrinter),
          action: isPermission
              ? SnackBarAction(
                  label: 'Allow',
                  onPressed: () => context.push('/permissions'),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connect(PrinterDevice device) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      await _printer.connect(device);
      if (!mounted) return;
      setState(() {
        _connected = true;
        _connectedName = device.name;
      });
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.commonSuccess)),
      );
    } on PrinterException {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.errorsPrinter)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
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

  Future<void> _testPrint(String paper) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final store = ref.read(storeProfileProvider).valueOrNull;
      final bytes = await ref.read(receiptBuilderProvider).testPage(
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
  }

  Future<void> _reprintLast() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final store = ref.read(storeProfileProvider).valueOrNull;
      if (store == null) return;
      final last = await ref
          .read(salesRepositoryProvider)
          .lastCompletedInvoice(store.id);
      if (!mounted) return;
      if (last == null) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('No completed bill to reprint')),
        );
        return;
      }
      final ok = await printInvoice(ref, last);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Last bill sent to printer' : l10n.errorsPrinter,
          ),
        ),
      );
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
          _ConnectionHero(
            connected: _connected,
            name: _connectedName,
            noneLabel: l10n.printerNone,
          ),
          const SizedBox(height: 14),
          SoftCard(
            radius: AppRadii.lg,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedRuler,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.printerPaperSize,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SoftPeriodBadge(
                      label: '58mm',
                      selected: paper == '58mm',
                      onTap: () => ref
                          .read(appSettingsProvider.notifier)
                          .setPaperSize('58mm'),
                    ),
                    SoftPeriodBadge(
                      label: '80mm',
                      selected: paper == '80mm',
                      onTap: () => ref
                          .read(appSettingsProvider.notifier)
                          .setPaperSize('80mm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_connected) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _scanning || _busy ? null : _scan,
                icon: _scanning
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.bluetooth_searching_rounded),
                label: Text(
                  _scanning ? 'Scanning…' : l10n.printerConnect,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_devices.isEmpty)
              SoftCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withValues(alpha: 0.16),
                            scheme.primary.withValues(alpha: 0.04),
                          ],
                        ),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedBluetooth,
                          size: 28,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasScanned
                          ? 'No printers found'
                          : 'Ready to scan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasScanned
                          ? 'Make sure your Bluetooth printer is on and paired, then scan again.'
                          : 'Tap Connect to search for nearby Bluetooth printers.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'Available printers',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              SoftCard(
                radius: AppRadii.lg,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < _devices.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: scheme.outline.withValues(alpha: 0.35),
                        ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedPrinter,
                              size: 20,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          _devices[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(_devices[i].address),
                        trailing: Icon(
                          Icons.link_rounded,
                          color: scheme.primary,
                        ),
                        onTap: _busy ? null : () => _connect(_devices[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ] else ...[
            SoftCard(
              radius: AppRadii.lg,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: [
                  _ActionRow(
                    icon: HugeIcons.strokeRoundedPrinter,
                    accent: scheme.primary,
                    title: l10n.printerTest,
                    subtitle: 'Print a sample receipt',
                    onTap: _busy ? null : () => _testPrint(paper),
                  ),
                  Divider(
                    height: 18,
                    color: scheme.outline.withValues(alpha: 0.35),
                  ),
                  _ActionRow(
                    icon: HugeIcons.strokeRoundedInvoice01,
                    accent: const Color(0xFF2563EB),
                    title: l10n.printerLastBill,
                    subtitle: 'Reprint your last completed bill',
                    onTap: _busy ? null : _reprintLast,
                  ),
                  Divider(
                    height: 18,
                    color: scheme.outline.withValues(alpha: 0.35),
                  ),
                  _ActionRow(
                    icon: HugeIcons.strokeRoundedLinkBackward,
                    accent: scheme.error,
                    title: l10n.printerDisconnect,
                    subtitle: 'Stop using this printer',
                    onTap: _busy ? null : _disconnect,
                    destructive: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionHero extends StatelessWidget {
  const _ConnectionHero({
    required this.connected,
    required this.name,
    required this.noneLabel,
  });

  final bool connected;
  final String? name;
  final String noneLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = connected ? AppColors.success : scheme.onSurfaceVariant;

    return SoftCard(
      radius: AppRadii.xl,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      color: connected ? AppColors.success.withValues(alpha: 0.07) : null,
      borderColor:
          connected ? AppColors.success.withValues(alpha: 0.28) : null,
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
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Center(
              child: HugeIcon(
                icon: connected
                    ? HugeIcons.strokeRoundedBluetooth
                    : HugeIcons.strokeRoundedBluetoothNotConnected,
                size: 34,
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            connected ? 'Printer connected' : noneLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: connected ? AppColors.success : null,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            connected
                ? (name?.trim().isNotEmpty == true
                    ? name!
                    : 'Ready to print receipts')
                : 'Connect a Bluetooth printer to print bills and test pages.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final List<List<dynamic>> icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(icon: icon, size: 20, color: accent),
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
                          color: destructive ? scheme.error : null,
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
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
