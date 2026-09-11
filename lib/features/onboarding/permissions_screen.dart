import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/services/app_permission_service.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

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
      icon: Icons.photo_camera_outlined,
    ),
    _PermDef(
      permission: Permission.bluetoothScan,
      title: 'Bluetooth scan',
      subtitle: 'Find nearby Bluetooth receipt printers.',
      icon: Icons.bluetooth_searching_rounded,
    ),
    _PermDef(
      permission: Permission.bluetoothConnect,
      title: 'Bluetooth connect',
      subtitle: 'Connect and print to paired printers.',
      icon: Icons.bluetooth_connected_rounded,
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

  void _continue() => context.go('/home');

  String _statusLabel(PermissionStatus? status) {
    if (status == null) return 'Checking…';
    if (status.isGranted) return 'Allowed';
    if (status.isPermanentlyDenied) return 'Denied — open Settings';
    if (status.isDenied) return 'Not allowed';
    if (status.isRestricted) return 'Restricted';
    return status.name;
  }

  Color _statusColor(PermissionStatus? status, ColorScheme scheme) {
    if (status?.isGranted == true) return AppColors.success;
    if (status?.isPermanentlyDenied == true) return scheme.error;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allGranted = _items.every(
      (item) => _statuses[item.permission]?.isGranted == true,
    );

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App permissions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'POS Billing needs these permissions for barcode scanning and Bluetooth printing. If a permission is denied, tap Allow.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final status = _statuses[item.permission];
                      final granted = status?.isGranted == true;
                      return SoftCard(
                        child: Row(
                          children: [
                            IconBadge(icon: item.icon, size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _statusLabel(status),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: _statusColor(status, scheme),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (granted)
                              Icon(Icons.check_circle_rounded,
                                  color: AppColors.success)
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
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              if (!allGranted)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _requesting ? null : _allowAll,
                    child: const Text('Allow all'),
                  ),
                ),
              if (!allGranted) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: allGranted
                    ? FilledButton(
                        onPressed: _continue,
                        child: const Text('Continue'),
                      )
                    : OutlinedButton(
                        onPressed: _continue,
                        child: const Text('Continue anyway'),
                      ),
              ),
            ],
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
  final IconData icon;
}
