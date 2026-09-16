import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

final _categorySearch = StateProvider<String>((ref) => '');

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _showCategoryActions(
    BuildContext context,
    WidgetRef ref, {
    required Category category,
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
                  subtitle: const Text('Rename this category'),
                  onTap: () => Navigator.pop(ctx, 'update'),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  title: const Text('Delete'),
                  subtitle: const Text('Remove from product forms'),
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
      final saved = await context.push<bool>(
        '/categories/edit?id=${category.id}&name=${Uri.encodeComponent(category.name)}',
      );
      if (saved == true) ref.invalidate(categoriesProvider);
      return;
    }

    final ok = await confirmDialog(
      context,
      title: 'Delete category',
      body: 'Remove "${category.name}" from product forms?',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(productRepositoryProvider).deactivateCategory(category.id);
    ref.invalidate(categoriesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cats = ref.watch(categoriesProvider);
    final query = ref.watch(_categorySearch).trim().toLowerCase();
    final scheme = Theme.of(context).colorScheme;
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.categoriesTitle,
        subtitle: 'Organize your product catalog',
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
          const SizedBox(height: 2),
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
                    title: query.isEmpty
                        ? 'No categories found'
                        : 'No matching categories',
                    subtitle: query.isEmpty
                        ? 'Add categories to organize your products.'
                        : 'Try a different search name.',
                    showIcon: false,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final cat = filtered[i];
                    return SoftCard(
                      radius: AppRadii.md,
                      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                      onTap: () => _showCategoryActions(
                        context,
                        ref,
                        category: cat,
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
                                    icon: HugeIcons.strokeRoundedFolder01,
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
                                  cat.name.displayTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Product category',
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
                          Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant,
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
