import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    return Scaffold(
      appBar: GlassPageHeader(
        title: l10n.reportsTitle,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
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
          return (payments, top, value, stats, expensesTotal, expenses);
        }(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (payments, top, value, stats, expensesTotal, expenses) =
              snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date range',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickFrom,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text('From ${dateFmt.format(_from)}'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTo,
                            icon: const Icon(Icons.event_outlined),
                            label: Text('To ${dateFmt.format(_to)}'),
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
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.28,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  StatTile(
                    label: l10n.dashboardTodaySales,
                    value: Money(stats.todaySalesPaise).format(symbol: symbol),
                    icon: Icons.currency_rupee_rounded,
                  ),
                  StatTile(
                    label: l10n.dashboardBillsToday,
                    value: '${stats.billsToday}',
                    icon: Icons.receipt_long_rounded,
                    accent: AppColors.success,
                  ),
                  StatTile(
                    label: l10n.reportsStockValue,
                    value: Money(value).format(symbol: symbol),
                    icon: Icons.inventory_2_rounded,
                  ),
                  StatTile(
                    label: l10n.reportsExpenses,
                    value: Money(expensesTotal).format(symbol: symbol),
                    icon: Icons.payments_outlined,
                    accent: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionHeader(title: 'Collections'),
              const SizedBox(height: 10),
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _paymentRow(
                      context,
                      'CASH',
                      Money(payments[PaymentMethods.cash] ?? 0)
                          .format(symbol: symbol),
                      Icons.payments_outlined,
                    ),
                    const Divider(),
                    _paymentRow(
                      context,
                      'UPI',
                      Money(payments[PaymentMethods.upi] ?? 0)
                          .format(symbol: symbol),
                      Icons.qr_code_2_rounded,
                    ),
                    const Divider(),
                    _paymentRow(
                      context,
                      'CARD',
                      Money(payments[PaymentMethods.card] ?? 0)
                          .format(symbol: symbol),
                      Icons.credit_card_rounded,
                    ),
                    const Divider(),
                    _paymentRow(
                      context,
                      'CREDIT',
                      Money(payments[PaymentMethods.credit] ?? 0)
                          .format(symbol: symbol),
                      Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionHeader(title: l10n.reportsTopProducts),
              const SizedBox(height: 10),
              if (top.isEmpty)
                SoftCard(
                  child: Text(
                    l10n.salesEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < top.length; i++) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
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
              const SizedBox(height: 18),
              SectionHeader(title: l10n.reportsExpenses),
              const SizedBox(height: 10),
              if (expenses.isEmpty)
                SoftCard(
                  child: Text(
                    'No expenses in this period',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < expenses.length; i++) ...[
                        if (i > 0) const Divider(),
                        ListTile(
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

  Widget _paymentRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return ListTile(
      leading: IconBadge(icon: icon, size: 38),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
