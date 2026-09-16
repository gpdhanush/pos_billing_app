import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/services/app_permission_service.dart';
import 'package:pos_billing/features/onboarding/onboarding_widgets.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with WidgetsBindingObserver {
  final _service = const AppPermissionService();
  final Map<Permission, PermissionStatus> _statuses = {};
  bool _loading = true;
  bool _requesting = false;

  static const _items = <_PermDef>[
    _PermDef(
      permission: Permission.camera,
      title: 'Camera',
      subtitle: 'Scan product barcodes during billing.',
      icon: HugeIcons.strokeRoundedCamera01,
    ),
    _PermDef(
      permission: Permission.bluetoothScan,
      title: 'Bluetooth scan',
      subtitle: 'Find nearby Bluetooth receipt printers.',
      icon: HugeIcons.strokeRoundedBluetoothSearch,
    ),
    _PermDef(
      permission: Permission.bluetoothConnect,
      title: 'Bluetooth connect',
      subtitle: 'Connect and print to paired printers.',
      icon: HugeIcons.strokeRoundedBluetooth,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final next = <Permission, PermissionStatus>{};
    for (final item in _items) {
      next[item.permission] = await _service.statusOf(item.permission);
    }
    if (!mounted) return;
    setState(() {
      _statuses
        ..clear()
        ..addAll(next);
      _loading = false;
    });
  }

  Future<void> _allow(Permission permission) async {
    setState(() => _requesting = true);
    final current = await _service.statusOf(permission);
    if (current.isPermanentlyDenied || current.isRestricted) {
      await _service.openSettings();
      await _refresh();
      if (mounted) setState(() => _requesting = false);
      return;
    }

    final status = await _service.request(permission);
    if (!mounted) return;

    if (status.isPermanentlyDenied || status.isRestricted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission needed'),
          content: const Text(
            'This permission was denied. Open Settings and allow it for POS Billing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _service.openSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
    }

    await _refresh();
    if (mounted) setState(() => _requesting = false);
  }

  Future<void> _allowAll() async {
    setState(() => _requesting = true);
    await _service.requestAll();
    await _refresh();

    final denied = _items.where((item) {
      final status = _statuses[item.permission];
      return status == null || !status.isGranted;
    }).toList();

    if (denied.isNotEmpty && mounted) {
      final permanentlyDenied = denied.any((item) {
        final status = _statuses[item.permission];
        return status?.isPermanentlyDenied == true;
      });
      if (permanentlyDenied) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Allow permissions'),
            content: const Text(
              'Some permissions are still denied. Open Settings to allow Bluetooth and Camera.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _service.openSettings();
                },
                child: const Text('Open settings'),
              ),
            ],
          ),
        );
      }
    }

    if (mounted) setState(() => _requesting = false);
  }

  void _continue() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  String _statusLabel(PermissionStatus? status) {
    if (status == null) return 'Checking…';
    if (status.isGranted) return 'Allowed';
    if (status.isPermanentlyDenied) return 'Denied — open Settings';
    if (status.isDenied) return 'Not allowed';
    if (status.isRestricted) return 'Restricted';
    return status.name;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allGranted = _items.every(
      (item) => _statuses[item.permission]?.isGranted == true,
    );

    return Scaffold(
      body: OnboardBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      size: 22,
                      color: scheme.onSurface,
                    ),
                  ),
                const OnboardHeroIcon(
                  icon: HugeIcons.strokeRoundedSecurityCheck,
                  size: 88,
                  iconSize: 38,
                ),
                const SizedBox(height: 20),
                Text(
                  'App permissions',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'POS Billing needs these permissions for barcode scanning and Bluetooth printing. If a permission is denied, tap Allow.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 22),
                if (_loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final status = _statuses[item.permission];
                        final granted = status?.isGranted == true;
                        final statusColor = granted
                            ? AppColors.success
                            : status?.isPermanentlyDenied == true
                                ? scheme.error
                                : AppColors.warning;
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 280 + (index * 80)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: OnboardOptionCard(
                            title: item.title,
                            subtitle: item.subtitle,
                            icon: item.icon,
                            selected: granted,
                            onTap: granted || _requesting
                                ? () {}
                                : () => _allow(item.permission),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (granted)
                                  HugeIcon(
                                    icon: HugeIcons
                                        .strokeRoundedCheckmarkCircle02,
                                    size: 24,
                                    color: AppColors.success,
                                    strokeWidth: 1.8,
                                  )
                                else
                                  FilledButton(
                                    onPressed: _requesting
                                        ? null
                                        : () => _allow(item.permission),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(84, 40),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                    ),
                                    child: Text(
                                      status?.isPermanentlyDenied == true
                                          ? 'Settings'
                                          : 'Allow',
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  _statusLabel(status),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                if (!allGranted)
                  OnboardPrimaryButton(
                    label: 'Allow all',
                    icon: HugeIcons.strokeRoundedSecurityCheck,
                    loading: _requesting,
                    onPressed: _allowAll,
                  ),
                if (!allGranted) const SizedBox(height: 8),
                if (allGranted)
                  OnboardPrimaryButton(
                    label: 'Continue',
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    onPressed: _continue,
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _continue,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                      ),
                      child: const Text('Continue anyway'),
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

class _PermDef {
  const _PermDef({
    required this.permission,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final Permission permission;
  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
}
