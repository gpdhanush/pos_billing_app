import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
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
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(productsProvider);
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? '${l10n.dashboardGreetingMorning} ☀️'
        : hour < 17
            ? '${l10n.dashboardGreetingAfternoon} 🌤'
            : '${l10n.dashboardGreetingEvening} 🌙';
    final scheme = Theme.of(context).colorScheme;
    final storeName = store?.name ?? 'Your Business';
    final symbol = store?.currencySymbol ?? '₹';

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        top: true,
        left: true,
        right: true,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(salesListProvider);
            ref.invalidate(storeProfileProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 2),
                            Text(
                              'Manage your business with ease',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _RoundHeaderButton(
                        icon: HugeIcons.strokeRoundedNotification03,
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ),
              ),
              ContainedSliver(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _SectionLinkHeader(
                  title: "Today's overview",
                  actionLabel: 'View all',
                  onAction: () => context.push('/reports'),
                ),
              ),
              ContainedSliver(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: stats.when(
                  loading: () => const SizedBox(
                    height: 168,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => ErrorState(
                    onRetry: () => ref.invalidate(dashboardStatsProvider),
                  ),
                  data: (data) {
                    if (data == null) return const SizedBox.shrink();
                    return _TodayOverviewGrid(
                      bills: '${data.billsToday}',
                      stock: '${data.itemsInStock}',
                      lowStock: '${data.lowStockCount}',
                      billsLabel: l10n.dashboardBillsToday,
                      stockLabel: l10n.dashboardItemsInStock,
                      lowStockLabel: l10n.dashboardLowStock,
                    );
                  },
                ),
              ),
              ContainedSliver(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: stats.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (data) {
                    if (data == null) return const SizedBox.shrink();
                    return _WeekSalesChart(
                      title: 'This week',
                      subtitle: 'Sunday – Saturday',
                      values: data.last7DaysSalesPaise,
                      changePercent: data.salesChangePercent,
                      symbol: symbol,
                    );
                  },
                ),
              ),
              if (store != null && store.completionPercent < 100)
                ContainedSliver(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _StoreSetupCard(
                    percent: store.completionPercent,
                    title: l10n.storeSetupReminderTitle(store.completionPercent),
                    body: l10n.storeSetupReminderBody,
                    onContinue: () => context.push('/settings/store'),
                  ),
                ),
              if (_needsCatalogSetup(categories, products))
                ContainedSliver(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _GetStartedCard(
                    onAddCategory: () => context.push('/categories/edit'),
                    onAddProduct: () => context.push('/products/edit'),
                  ),
                ),
              ContainedSliver(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Text(
                  l10n.dashboardQuickActions,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              ContainedSliver(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SoftCard(
                  radius: AppRadii.md,
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionChip(
                          label: l10n.dashboardAddProduct,
                          icon: HugeIcons.strokeRoundedPackageAdd,
                          accent: AppColors.success,
                          filled: true,
                          onTap: () => context.push('/products/edit'),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionChip(
                          label: l10n.categoriesAdd,
                          icon: HugeIcons.strokeRoundedTag01,
                          accent: const Color(0xFF7C3AED),
                          onTap: () => context.push('/categories/edit'),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionChip(
                          label: l10n.expensesAdd,
                          icon: HugeIcons.strokeRoundedWallet01,
                          accent: AppColors.danger,
                          onTap: () => context.push('/expenses/edit'),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionChip(
                          label: l10n.customersAdd,
                          icon: HugeIcons.strokeRoundedUserAdd01,
                          accent: scheme.primary,
                          onTap: () => context.push('/customers/edit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ContainedSliver(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLinkHeader(
                  title: l10n.dashboardRecentBills,
                  actionLabel: 'View all',
                  onAction: () => context.push('/sales'),
                ),
              ),
              ContainedSliver(
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
                        radius: AppRadii.md,
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
                    return Column(
                      children: [
                        for (var i = 0; i < recent.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _RecentBillCard(
                            invoice: recent[i],
                            symbol: symbol,
                            walkInLabel: l10n.billingWalkIn,
                            onTap: () =>
                                context.push('/invoice/${recent[i].id}'),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContainedSliver extends StatelessWidget {
  const ContainedSliver({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(padding: padding, child: child),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({
    required this.icon,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: HugeIcon(icon: icon, size: 20, color: scheme.primary),
        ),
      ),
    );
  }
}

class _SectionLinkHeader extends StatelessWidget {
  const _SectionLinkHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            visualDensity: VisualDensity.compact,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 2),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 14,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayOverviewGrid extends StatelessWidget {
  const _TodayOverviewGrid({
    required this.bills,
    required this.stock,
    required this.lowStock,
    required this.billsLabel,
    required this.stockLabel,
    required this.lowStockLabel,
  });

  final String bills;
  final String stock;
  final String lowStock;
  final String billsLabel;
  final String stockLabel;
  final String lowStockLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = scheme.outline.withValues(alpha: 0.45);

    return SoftCard(
      radius: AppRadii.md,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _OverviewCell(
                label: billsLabel,
                value: bills,
                icon: HugeIcons.strokeRoundedInvoice01,
                accent: AppColors.success,
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: line),
            Expanded(
              child: _OverviewCell(
                label: stockLabel,
                value: stock,
                icon: HugeIcons.strokeRoundedPackage,
                accent: const Color(0xFF7C3AED),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: line),
            Expanded(
              child: _OverviewCell(
                label: lowStockLabel,
                value: lowStock,
                icon: HugeIcons.strokeRoundedAlert02,
                accent: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCell extends StatelessWidget {
  const _OverviewCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final List<List<dynamic>> icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HugeIcon(icon: icon, size: 17, color: accent),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

class _WeekSalesChart extends StatelessWidget {
  const _WeekSalesChart({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.symbol,
    this.changePercent,
  });

  final String title;
  final String subtitle;
  final List<int> values;
  final String symbol;
  final double? changePercent;

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = values.length == 7 ? values : List<int>.filled(7, 0);
    final max = data.fold<int>(0, (a, b) => a > b ? a : b);
    final todayIndex = DateTime.now().weekday % 7; // Sun=0 … Sat=6
    final weekTotal = data.fold<int>(0, (a, b) => a + b);
    final up = (changePercent ?? 0) >= 0;

    return SoftCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (changePercent != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (up ? AppColors.success : AppColors.danger)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        up
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: up ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${up ? '+' : ''}${changePercent!.toStringAsFixed(0)}%',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color:
                                      up ? AppColors.success : AppColors.danger,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Money(weekTotal).format(symbol: symbol),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                              width: double.infinity,
                              height: max <= 0
                                  ? 12
                                  : (12 + (data[i] / max) * 78)
                                      .clamp(12, 90)
                                      .toDouble(),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: i == todayIndex
                                      ? [
                                          scheme.primary,
                                          Color.lerp(
                                            scheme.primary,
                                            const Color(0xFF38BDF8),
                                            0.35,
                                          )!,
                                        ]
                                      : [
                                          scheme.primary
                                              .withValues(alpha: 0.18),
                                          scheme.primary
                                              .withValues(alpha: 0.42),
                                        ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dayLabels[i],
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: i == todayIndex
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                    fontWeight: i == todayIndex
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final List<List<dynamic>> icon;
  final Color accent;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: filled ? accent : accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  size: 22,
                  color: filled ? Colors.white : accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.15,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreSetupCard extends StatelessWidget {
  const _StoreSetupCard({
    required this.percent,
    required this.title,
    required this.body,
    required this.onContinue,
  });

  final int percent;
  final String title;
  final String body;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    size: 22,
                    color: scheme.primary,
                  ),
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
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onContinue,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 2),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 14,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentBillCard extends StatelessWidget {
  const _RecentBillCard({
    required this.invoice,
    required this.symbol,
    required this.walkInLabel,
    required this.onTap,
  });

  final InvoiceSummary invoice;
  final String symbol;
  final String walkInLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paid = invoice.status == InvoiceStatus.completed;
    final when = DateFormat('d MMM yyyy, h:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(invoice.createdAt),
    );
    final number = invoice.invoiceNumber.startsWith('#')
        ? invoice.invoiceNumber
        : '#${invoice.invoiceNumber}';

    return SoftCard(
      radius: AppRadii.md,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedInvoice01,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    when,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money(invoice.totalPaise).format(symbol: symbol),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (paid ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    paid ? 'Paid' : invoice.status.displayTitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: paid ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
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

bool _needsCatalogSetup(
  AsyncValue<List<Category>> categories,
  AsyncValue<List<Product>> products,
) {
  final cats = categories.valueOrNull;
  final prods = products.valueOrNull;
  if (cats == null || prods == null) return false;
  return cats.isEmpty || prods.isEmpty;
}

class _GetStartedCard extends StatelessWidget {
  const _GetStartedCard({
    required this.onAddCategory,
    required this.onAddProduct,
  });

  final VoidCallback onAddCategory;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      radius: AppRadii.md,
      color: scheme.primary.withValues(alpha: 0.05),
      borderColor: scheme.outline.withValues(alpha: 0.55),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get Started',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set up your shop by adding products to your inventory',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: onAddCategory,
                child: const Text('Add Category'),
              ),
              FilledButton.tonal(
                onPressed: onAddProduct,
                child: const Text('Add Product'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
