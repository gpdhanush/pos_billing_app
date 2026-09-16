import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
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

  static const _trackedPermissions = <Permission>[
    Permission.camera,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ];

  List<({Permission permission, String title, String subtitle, List<List<dynamic>> icon})>
      _items(AppLocalizations l10n) {
    return [
      (
        permission: Permission.camera,
        title: l10n.commonCamera,
        subtitle: l10n.permissionsCameraHint,
        icon: HugeIcons.strokeRoundedCamera01,
      ),
      (
        permission: Permission.bluetoothScan,
        title: l10n.permissionsBluetoothScan,
        subtitle: l10n.permissionsBluetoothScanHint,
        icon: HugeIcons.strokeRoundedBluetoothSearch,
      ),
      (
        permission: Permission.bluetoothConnect,
        title: l10n.permissionsBluetoothConnect,
        subtitle: l10n.permissionsBluetoothConnectHint,
        icon: HugeIcons.strokeRoundedBluetooth,
      ),
    ];
  }

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
    for (final permission in _trackedPermissions) {
      next[permission] = await _service.statusOf(permission);
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
      final l10n = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.commonPermissionNeeded),
          content: Text(l10n.permissionsAllowTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _service.openSettings();
              },
              child: Text(l10n.commonOpenSettings),
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

    final denied = _trackedPermissions.where((permission) {
      final status = _statuses[permission];
      return status == null || !status.isGranted;
    }).toList();

    if (denied.isNotEmpty && mounted) {
      final permanentlyDenied = denied.any((permission) {
        final status = _statuses[permission];
        return status?.isPermanentlyDenied == true;
      });
      if (permanentlyDenied) {
        final l10n = AppLocalizations.of(context);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.permissionsAllowTitle),
            content: Text(l10n.permissionsAllowTitle),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.commonLater),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _service.openSettings();
                },
                child: Text(l10n.commonOpenSettings),
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

  String _statusLabel(AppLocalizations l10n, PermissionStatus? status) {
    if (status == null) return l10n.commonLoading;
    if (status.isGranted) return l10n.commonAllow;
    if (status.isPermanentlyDenied) return l10n.commonOpenSettings;
    if (status.isDenied) return l10n.commonLater;
    if (status.isRestricted) return l10n.commonFailed;
    return status.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = _items(l10n);
    final allGranted = items.every(
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
                  l10n.permissionsAllowTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.permissionsCameraHint,
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
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
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
                                          ? l10n.commonOpenSettings
                                          : l10n.commonAllow,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  _statusLabel(l10n, status),
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
                    label: l10n.permissionsAllowAll,
                    icon: HugeIcons.strokeRoundedSecurityCheck,
                    loading: _requesting,
                    onPressed: _allowAll,
                  ),
                if (!allGranted) const SizedBox(height: 8),
                if (allGranted)
                  OnboardPrimaryButton(
                    label: l10n.commonContinue,
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
                      child: Text(l10n.permissionsContinueAnyway),
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
