import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/repositories/sales_repository.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/core/services/reports_pdf_exporter.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _exporting = false;
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _to = _from;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesRangeProvider.notifier).state =
          SalesDateRange.custom(_from, _to);
    });
  }

  String _rangeLabel(AppLocalizations l10n, SalesDateRange range) {
    final today = SalesDateRange.today();
    final yesterday = SalesDateRange.yesterday();
    final week = SalesDateRange.thisWeek();
    final month = SalesDateRange.thisMonth();
    if (range.startMs == today.startMs && range.endMs == today.endMs) {
      return l10n.salesToday;
    }
    if (range.startMs == yesterday.startMs && range.endMs == yesterday.endMs) {
      return l10n.salesYesterday;
    }
    if (range.startMs == week.startMs && range.endMs == week.endMs) {
      return l10n.salesThisWeek;
    }
    if (range.startMs == month.startMs && range.endMs == month.endMs) {
      return l10n.salesThisMonth;
    }
    final fmt = DateFormat('dd MMM yyyy');
    final start = DateTime.fromMillisecondsSinceEpoch(range.startMs);
    final end = DateTime.fromMillisecondsSinceEpoch(range.endMs)
        .subtract(const Duration(milliseconds: 1));
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return fmt.format(start);
    }
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }

  void _applyRange(SalesDateRange range) {
    ref.read(salesRangeProvider.notifier).state = range;
    setState(() {
      _from = DateTime.fromMillisecondsSinceEpoch(range.startMs);
      _to = DateTime.fromMillisecondsSinceEpoch(range.endMs)
          .subtract(const Duration(milliseconds: 1));
      _to = DateTime(_to.year, _to.month, _to.day);
    });
  }

  Future<void> _pickFrom() async {
    final picked = await showAppDatePicker(
      context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: _to,
    );
    if (picked == null) return;
    setState(() => _from = DateTime(picked.year, picked.month, picked.day));
    ref.read(salesRangeProvider.notifier).state =
        SalesDateRange.custom(_from, _to);
  }

  Future<void> _pickTo() async {
    final picked = await showAppDatePicker(
      context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _to = DateTime(picked.year, picked.month, picked.day));
    ref.read(salesRangeProvider.notifier).state =
        SalesDateRange.custom(_from, _to);
  }

  Future<void> _exportPdf({
    required Map<String, int> payments,
    required List<(String, int, int)> top,
    required int stockValue,
    required dynamic stats,
    required int expensesTotal,
    required List<Expense> expenses,
  }) async {
    final l10n = AppLocalizations.of(context);
    final store = ref.read(storeProfileProvider).valueOrNull;
    if (store == null) return;
    setState(() => _exporting = true);
    try {
      final range = ref.read(salesRangeProvider);
      await ReportsPdfExporter().exportAndShare(
        store: store,
        rangeLabel: _rangeLabel(l10n, range),
        todaySalesPaise: stats.todaySalesPaise as int,
        billsToday: stats.billsToday as int,
        stockValuePaise: stockValue,
        expensesPaise: expensesTotal,
        payments: payments,
        topProducts: top,
        expenses: expenses,
      );
    } catch (_) {
      if (mounted) showSnack(context, 'Unable to export report PDF');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final range = ref.watch(salesRangeProvider);
    if (store == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final symbol = store.currencySymbol;
    final dateFmt = DateFormat('dd MMM yyyy');
    final scheme = Theme.of(context).colorScheme;
    final canPop = context.canPop();
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.reportsTitle,
        subtitle: 'View your business insights',
        height: 64,
        leading: canPop
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
      ),
      body: FutureBuilder(
        key: ValueKey('${range.startMs}-${range.endMs}'),
        future: () async {
          final sales = ref.read(salesRepositoryProvider);
          final expenseRepo = ref.read(expenseRepositoryProvider);
          final payments = await sales.paymentTotals(store.id, range);
          final top = await sales.topProducts(store.id, range);
          final value = await sales.stockValuePaise(store.id);
          final stats = await sales.dashboardStats(store.id);
          final expensesTotal = await expenseRepo.total(
            store.id,
            startMs: range.startMs,
            endMs: range.endMs,
          );
          final expenses = await expenseRepo.listInRange(
            store.id,
            startMs: range.startMs,
            endMs: range.endMs,
          );
          return (
            payments,
            top,
            value,
            stats,
            expensesTotal,
            expenses,
          );
        }(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (
            payments,
            top,
            value,
            stats,
            expensesTotal,
            expenses,
          ) = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SoftCard(
                radius: AppRadii.lg,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                              icon: HugeIcons.strokeRoundedCalendar03,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Date range',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'From',
                            value: dateFmt.format(_from),
                            onTap: _pickFrom,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateField(
                            label: 'To',
                            value: dateFmt.format(_to),
                            onTap: _pickTo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickChip(l10n.salesToday, SalesDateRange.today()),
                          _quickChip(
                            l10n.salesYesterday,
                            SalesDateRange.yesterday(),
                          ),
                          _quickChip(
                            l10n.salesThisWeek,
                            SalesDateRange.thisWeek(),
                          ),
                          _quickChip(
                            l10n.salesThisMonth,
                            SalesDateRange.thisMonth(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _exporting
                            ? null
                            : () => _exportPdf(
                                  payments: payments,
                                  top: top,
                                  stockValue: value,
                                  stats: stats,
                                  expensesTotal: expensesTotal,
                                  expenses: expenses,
                                ),
                        icon: _exporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(
                          _exporting
                              ? 'Exporting…'
                              : 'Export PDF (${_rangeLabel(l10n, range)})',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ReportSectionHeader(
                title: 'Collections',
                icon: HugeIcons.strokeRoundedWallet01,
                accent: AppColors.success,
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.35,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _ReportMetricCard(
                    label: 'CASH',
                    value: Money(payments[PaymentMethods.cash] ?? 0)
                        .format(symbol: symbol),
                    accent: AppColors.success,
                    icon: HugeIcons.strokeRoundedMoney01,
                  ),
                  _ReportMetricCard(
                    label: 'UPI',
                    value: Money(payments[PaymentMethods.upi] ?? 0)
                        .format(symbol: symbol),
                    accent: const Color(0xFF2563EB),
                    icon: HugeIcons.strokeRoundedQrCode,
                  ),
                  _ReportMetricCard(
                    label: 'CARD',
                    value: Money(payments[PaymentMethods.card] ?? 0)
                        .format(symbol: symbol),
                    accent: const Color(0xFF7C3AED),
                    icon: HugeIcons.strokeRoundedCreditCard,
                  ),
                  _ReportMetricCard(
                    label: 'CREDIT',
                    value: Money(payments[PaymentMethods.credit] ?? 0)
                        .format(symbol: symbol),
                    accent: const Color(0xFFEA580C),
                    icon: HugeIcons.strokeRoundedWallet01,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ReportSectionHeader(
                title: l10n.reportsTopProducts,
                icon: HugeIcons.strokeRoundedChartBarLine,
                accent: AppColors.success,
              ),
              const SizedBox(height: 10),
              if (top.isEmpty)
                _ReportEmptyCard(
                  icon: HugeIcons.strokeRoundedChartBarLine,
                  accent: AppColors.success,
                  title: 'No top products yet',
                  subtitle:
                      'Sales in this period will appear here once you record bills.',
                )
              else
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < top.length; i++) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedPackage01,
                                size: 20,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          title: Text(top[i].$1.displayTitle),
                          subtitle: Text(
                            '${l10n.commonQuantity}: ${top[i].$2}',
                          ),
                          trailing: Text(
                            Money(top[i].$3).format(symbol: symbol),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              _ReportSectionHeader(
                title: l10n.reportsExpenses,
                icon: HugeIcons.strokeRoundedWallet02,
                accent: AppColors.danger,
              ),
              const SizedBox(height: 10),
              if (expenses.isEmpty)
                _ReportEmptyCard(
                  icon: HugeIcons.strokeRoundedWallet02,
                  accent: AppColors.danger,
                  title: 'No expenses yet',
                  subtitle:
                      'Expenses logged in this date range will show up here.',
                )
              else
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < expenses.length; i++) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedWallet02,
                                size: 20,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                          title: Text(expenses[i].category.displayTitle),
                          subtitle: Text(
                            '${expenses[i].paymentMethod.toUpperCase()} · ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(expenses[i].spentAt))}',
                          ),
                          trailing: Text(
                            Money(expenses[i].amountPaise)
                                .format(symbol: symbol),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickChip(String label, SalesDateRange value) {
    final current = ref.watch(salesRangeProvider);
    final selected =
        current.startMs == value.startMs && current.endMs == value.endMs;
    return SoftPeriodBadge(
      label: label,
      selected: selected,
      onTap: () => _applyRange(value),
    );
  }

}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportEmptyCard extends StatelessWidget {
  const _ReportEmptyCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
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
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: HugeIcon(icon: icon, size: 28, color: accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
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

class _ReportSectionHeader extends StatelessWidget {
  const _ReportSectionHeader({
    required this.title,
    required this.icon,
    required this.accent,
  });

  final String title;
  final List<List<dynamic>> icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: HugeIcon(icon: icon, size: 18, color: accent),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.07),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: HugeIcon(icon: icon, size: 16, color: accent),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        height: 1.1,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
