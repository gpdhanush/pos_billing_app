import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final stats = ref.watch(dashboardStatsProvider);
    final sales = ref.watch(salesListProvider);
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? l10n.dashboardGreetingMorning
        : hour < 17
        ? l10n.dashboardGreetingAfternoon
        : l10n.dashboardGreetingEvening;
    final scheme = Theme.of(context).colorScheme;
    final storeName = store?.name ?? 'Your Business';
    final symbol = store?.currencySymbol ?? '₹';
    final todayLabel = DateFormat('EEE, d MMM').format(DateTime.now());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.10),
              scheme.surface,
              scheme.surface,
            ],
            stops: const [0, 0.28, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(salesListProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greet,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                storeName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: l10n.navMore,
                          onPressed: () => context.go('/more'),
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.surface,
                            foregroundColor: scheme.onSurface,
                            side: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.7),
                            ),
                          ),
                          icon: const Icon(Icons.apps_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: _HeroSalesCard(
                      l10n: l10n,
                      todayLabel: todayLabel,
                      symbol: symbol,
                      stats: stats,
                      onRetry: () => ref.invalidate(dashboardStatsProvider),
                      onNewBill: () => context.go('/billing'),
                    ),
                  ),
                ),
                if (store != null && store.completionPercent < 100)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: SoftCard(
                        onTap: () => context.push('/settings/store'),
                        child: Row(
                          children: [
                            IconBadge(
                              icon: Icons.storefront_rounded,
                              background:
                                  scheme.primary.withValues(alpha: 0.10),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.storeSetupReminderTitle(
                                      store.completionPercent,
                                    ),
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.storeSetupReminderBody,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: stats.when(
                      loading: () => const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => ErrorState(
                        onRetry: () => ref.invalidate(dashboardStatsProvider),
                      ),
                      data: (data) {
                        if (data == null) return const SizedBox.shrink();
                        return Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: l10n.dashboardBillsToday,
                                value: '${data.billsToday}',
                                icon: Icons.receipt_long_rounded,
                                accent: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: l10n.dashboardItemsInStock,
                                value: '${data.itemsInStock}',
                                icon: Icons.inventory_2_rounded,
                                accent: scheme.tertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: l10n.dashboardLowStock,
                                value: '${data.lowStockCount}',
                                icon: Icons.warning_amber_rounded,
                                accent: AppColors.warning,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: SectionHeader(title: l10n.dashboardQuickActions),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        _ActionTile(
                          label: l10n.dashboardNewBill,
                          icon: Icons.add_rounded,
                          filled: true,
                          onTap: () => context.go('/billing'),
                        ),
                        _ActionTile(
                          label: l10n.dashboardScanProduct,
                          icon: Icons.qr_code_scanner_rounded,
                          onTap: () =>
                              context.push('/scan?purpose=addToCart'),
                        ),
                        _ActionTile(
                          label: l10n.dashboardAddProduct,
                          icon: Icons.add_box_rounded,
                          onTap: () => context.push('/products/edit'),
                        ),
                        _ActionTile(
                          label: l10n.dashboardAddStock,
                          icon: Icons.inventory_rounded,
                          onTap: () => context.go('/stock'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: SectionHeader(
                      title: l10n.dashboardRecentBills,
                      actionLabel: 'View all',
                      onAction: () => context.push('/sales'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                    child: sales.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => ErrorState(
                        onRetry: () => ref.invalidate(salesListProvider),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return SoftCard(
                            child: Text(
                              l10n.dashboardNoBills,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          );
                        }
                        final recent = items.take(6).toList();
                        return SoftCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < recent.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: scheme.outline
                                        .withValues(alpha: 0.45),
                                  ),
                                InkWell(
                                  onTap: () =>
                                      context.push('/sales/${recent[i].id}'),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        InitialsAvatar(
                                          label: recent[i].invoiceNumber,
                                          icon: Icons.receipt_long_rounded,
                                          size: 42,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recent[i].invoiceNumber,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                recent[i].customerName ??
                                                    l10n.billingWalkIn,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              Money(recent[i].totalPaise)
                                                  .format(symbol: symbol),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            Text(
                                              DateFormat.jm().format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                  recent[i].createdAt,
                                                ),
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
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

class _HeroSalesCard extends StatelessWidget {
  const _HeroSalesCard({
    required this.l10n,
    required this.todayLabel,
    required this.symbol,
    required this.stats,
    required this.onRetry,
    required this.onNewBill,
  });

  final AppLocalizations l10n;
  final String todayLabel;
  final String symbol;
  final AsyncValue<DashboardStats?> stats;
  final VoidCallback onRetry;
  final VoidCallback onNewBill;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.18)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SoftInfoBadge(
                label: todayLabel,
                background: Colors.white.withValues(alpha: 0.16),
                foreground: Colors.white,
              ),
              const Spacer(),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.dashboardTodaySales,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 6),
          stats.when(
            loading: () => Text(
              '—',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            error: (_, _) => TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(l10n.commonRetry),
            ),
            data: (data) {
              final amount = data == null
                  ? '—'
                  : Money(data.todaySalesPaise).format(symbol: symbol);
              return Text(
                amount,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
              );
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNewBill,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: scheme.primary,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.dashboardNewBill),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = filled ? scheme.primary : scheme.surface;
    final fg = filled ? scheme.onPrimary : scheme.onSurface;
    final iconBg = filled
        ? Colors.white.withValues(alpha: 0.18)
        : scheme.primary.withValues(alpha: 0.10);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: filled
                ? null
                : Border.all(color: scheme.outline.withValues(alpha: 0.75)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    icon,
                    color: filled ? Colors.white : scheme.primary,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
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
