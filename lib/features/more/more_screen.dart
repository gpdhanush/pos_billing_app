import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/theme/app_theme.dart';

/// Bottom-nav hub: feature shortcuts. App preferences live under Settings.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final items = <_MoreItem>[
      _MoreItem(
        icon: Icons.group_rounded,
        title: l10n.customersTitle,
        subtitle: 'Buyers & credit',
        onTap: () => context.push('/customers'),
      ),
      _MoreItem(
        icon: Icons.inventory_2_rounded,
        title: l10n.productsTitle,
        subtitle: 'Catalog & prices',
        onTap: () => context.push('/products'),
      ),
      _MoreItem(
        icon: Icons.category_rounded,
        title: l10n.categoriesTitle,
        subtitle: 'Organize items',
        onTap: () => context.push('/categories'),
      ),
      _MoreItem(
        icon: Icons.warehouse_rounded,
        title: 'Stocks',
        subtitle: 'Adjust inventory',
        onTap: () => context.go('/stock'),
      ),
      _MoreItem(
        icon: Icons.payments_rounded,
        title: l10n.expensesTitle,
        subtitle: 'Shop spending',
        onTap: () => context.push('/expenses'),
      ),
      _MoreItem(
        icon: Icons.insights_rounded,
        title: l10n.reportsTitle,
        subtitle: 'Sales overview',
        onTap: () => context.push('/reports'),
      ),
      _MoreItem(
        icon: Icons.settings_rounded,
        title: l10n.settingsTitle,
        subtitle: 'Store & security',
        onTap: () => context.push('/settings'),
        wide: true,
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 18,
                20,
                28,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary,
                    Color.lerp(scheme.primary, scheme.secondary, 0.35)!,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.navMore,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quick access to shop tools',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimary.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = items[i];
                  if (item.wide) {
                    return const SizedBox.shrink();
                  }
                  return _MoreTile(item: item);
                },
                childCount: items.length - 1,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverToBoxAdapter(
              child: _MoreTile(item: items.last, horizontal: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.wide = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool wide;
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.item, this.horizontal = false});

  final _MoreItem item;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: scheme.onSurface.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(horizontal ? 18 : 16),
            child: horizontal
                ? Row(
                    children: [
                      _iconBadge(scheme),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconBadge(scheme),
                      const Spacer(),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _iconBadge(ColorScheme scheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Icon(item.icon, color: scheme.primary, size: 26),
    );
  }
}
