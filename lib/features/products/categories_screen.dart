import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

final _categorySearch = StateProvider<String>((ref) => '');

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cats = ref.watch(categoriesProvider);
    final query = ref.watch(_categorySearch).trim().toLowerCase();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GlassPageHeader(
        title: l10n.categoriesTitle,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await context.push<bool>('/categories/edit');
          if (saved == true) ref.invalidate(categoriesProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.categoriesAdd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SoftSearchField(
              hintText: 'Search categories',
              onChanged: (v) => ref.read(_categorySearch.notifier).state = v,
            ),
          ),
          Expanded(
            child: cats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
              data: (items) {
                final filtered = query.isEmpty
                    ? items
                    : items
                        .where((c) => c.name.toLowerCase().contains(query))
                        .toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: l10n.categoriesTitle,
                    subtitle: 'Add categories to organize products.',
                    icon: Icons.category_outlined,
                    actionLabel: l10n.categoriesAdd,
                    onAction: () => context.push('/categories/edit'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.45),
                  ),
                  itemBuilder: (context, i) {
                    final cat = filtered[i];
                    return InkWell(
                      onTap: () async {
                        final saved = await context.push<bool>(
                          '/categories/edit?id=${cat.id}&name=${Uri.encodeComponent(cat.name)}',
                        );
                        if (saved == true) {
                          ref.invalidate(categoriesProvider);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cat.name.displayTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
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
                                  title: 'Delete category',
                                  body:
                                      'Remove "${cat.name}" from product forms?',
                                  icon: Icons.delete_outline_rounded,
                                  confirmLabel: 'Delete',
                                  destructive: true,
                                );
                                if (!ok) return;
                                await ref
                                    .read(productRepositoryProvider)
                                    .deactivateCategory(cat.id);
                                ref.invalidate(categoriesProvider);
                              },
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: scheme.error,
                              ),
                            ),
                          ],
                        ),
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
