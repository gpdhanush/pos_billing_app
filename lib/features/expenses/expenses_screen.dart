import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

final _expenseSearch = StateProvider<String>((ref) => '');

final expensesListProvider = FutureProvider.autoDispose<List<Expense>>((
  ref,
) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) return const [];
  final all = await ref.watch(expenseRepositoryProvider).list(store.id);
  final q = ref.watch(_expenseSearch).trim().toLowerCase();
  if (q.isEmpty) return all;
  return all
      .where(
        (e) =>
            e.category.toLowerCase().contains(q) ||
            e.paymentMethod.toLowerCase().contains(q) ||
            (e.note ?? '').toLowerCase().contains(q),
      )
      .toList();
});

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  Future<void> _showExpenseActions(
    BuildContext context,
    WidgetRef ref, {
    required Expense expense,
    required String symbol,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: scheme.primary),
                  title: const Text('Update'),
                  subtitle: const Text('Edit expense details'),
                  onTap: () => Navigator.pop(ctx, 'update'),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  title: const Text('Delete'),
                  subtitle: const Text('Remove this expense'),
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !context.mounted) return;

    if (action == 'update') {
      final saved = await context.push<bool>('/expenses/edit?id=${expense.id}');
      if (saved == true) ref.invalidate(expensesListProvider);
      return;
    }

    final ok = await confirmDialog(
      context,
      title: 'Delete expense',
      body:
          'Remove "${expense.category}" expense of ${Money(expense.amountPaise).format(symbol: symbol)}?',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(expenseRepositoryProvider).delete(expense.id);
    ref.invalidate(expensesListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(expensesListProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';
    final scheme = Theme.of(context).colorScheme;
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.expensesTitle,
        subtitle: 'Shop spending & costs',
        height: 64,
        leading: canPop
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await context.push<bool>('/expenses/edit');
          if (saved == true) ref.invalidate(expensesListProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.expensesAdd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SoftSearchField(
              hintText: 'Search expenses',
              onChanged: (v) => ref.read(_expenseSearch.notifier).state = v,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: list.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                onRetry: () => ref.invalidate(expensesListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'No expenses found',
                    subtitle: 'Record shop spending to track your costs.',
                    showIcon: false,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final date = DateFormat('dd MMM yyyy').format(
                      DateTime.fromMillisecondsSinceEpoch(e.spentAt),
                    );
                    final note = e.note?.trim();
                    final meta = [
                      e.paymentMethod.toUpperCase(),
                      date,
                      if (note != null && note.isNotEmpty) note,
                    ].join(' • ');

                    return SoftCard(
                      radius: AppRadii.md,
                      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                      onTap: () => _showExpenseActions(
                        context,
                        ref,
                        expense: e,
                        symbol: symbol,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: ColoredBox(
                                color: scheme.primary.withValues(alpha: 0.08),
                                child: Center(
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedMoney01,
                                    size: 22,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.category.displayTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  meta,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            Money(e.amountPaise).format(symbol: symbol),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
