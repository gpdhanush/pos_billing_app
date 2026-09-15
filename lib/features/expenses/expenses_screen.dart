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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(expensesListProvider);
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GlassPageHeader(
        title: l10n.expensesTitle,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final date = DateFormat.yMMMd().format(
                      DateTime.fromMillisecondsSinceEpoch(e.spentAt),
                    );
                    return SoftCard(
                      radius: AppRadii.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onTap: () async {
                        final saved = await context.push<bool>(
                          '/expenses/edit?id=${e.id}',
                        );
                        if (saved == true) {
                          ref.invalidate(expensesListProvider);
                        }
                      },
                      child: Row(
                        children: [
                          InitialsAvatar(
                            label: e.category,
                            icon: Icons.payments_outlined,
                            size: 36,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.category.displayTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${e.paymentMethod.toUpperCase()} · $date',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Money(e.amountPaise).format(
                              symbol: store?.currencySymbol ?? '₹',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            onPressed: () async {
                              final ok = await confirmDialog(
                                context,
                                title: 'Delete expense',
                                body:
                                    'Remove "${e.category}" expense of ${Money(e.amountPaise).format(symbol: store?.currencySymbol ?? '₹')}?',
                                icon: Icons.delete_outline_rounded,
                                confirmLabel: 'Delete',
                                destructive: true,
                              );
                              if (!ok) return;
                              await ref
                                  .read(expenseRepositoryProvider)
                                  .delete(e.id);
                              ref.invalidate(expensesListProvider);
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.error,
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
