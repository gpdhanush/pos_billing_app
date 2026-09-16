import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/features/sales/sales_screen.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

final customerDetailProvider =
    FutureProvider.autoDispose.family<Customer?, int>((ref, id) {
  return ref.watch(customerRepositoryProvider).get(id);
});

final customerOrdersProvider = FutureProvider.autoDispose
    .family<({int orderCount, int spentPaise, List<InvoiceSummary> recent}), int>((
  ref,
  customerId,
) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) {
    return (orderCount: 0, spentPaise: 0, recent: const <InvoiceSummary>[]);
  }
  return ref.watch(salesRepositoryProvider).customerOrderSummary(
        storeId: store.id,
        customerId: customerId,
      );
});

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerDetailProvider(customerId));
    final scheme = Theme.of(context).colorScheme;
    final store = ref.watch(storeProfileProvider).valueOrNull;
    final symbol = store?.currencySymbol ?? '₹';

    return async.when(
      loading: () => Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: ErrorState(
          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
        ),
      ),
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            backgroundColor: scheme.surfaceContainerLowest,
            appBar: GlassPageHeader(
              title: 'Customer Details',
              subtitle: 'View customer information',
              height: 64,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            body: const EmptyState(
              title: 'Customer not found',
              subtitle: 'It may have been removed.',
              showIcon: false,
            ),
          );
        }
        return _CustomerDetailBody(customer: customer, symbol: symbol);
      },
    );
  }
}

class _CustomerDetailBody extends ConsumerWidget {
  const _CustomerDetailBody({
    required this.customer,
    required this.symbol,
  });

  final Customer customer;
  final String symbol;

  static final _date = DateFormat('dd/MM/yyyy');

  void _createOrder(BuildContext context, WidgetRef ref) {
    ref.read(cartProvider.notifier).setCustomer(customer);
    context.go('/billing');
  }

  ({Color color, String label}) _statusStyle(String status) {
    switch (status) {
      case InvoiceStatus.cancelled:
        return (color: AppColors.danger, label: 'Cancelled');
      case InvoiceStatus.refunded:
        return (color: AppColors.warning, label: 'Refunded');
      case InvoiceStatus.completed:
        return (color: AppColors.success, label: 'Paid');
      default:
        return (color: AppColors.warning, label: 'Pending');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final orders = ref.watch(customerOrdersProvider(customer.id));
    final memberSince = _date.format(
      DateTime.fromMillisecondsSinceEpoch(customer.createdAt),
    );
    final phone = (customer.phone ?? '').trim();
    final email = (customer.email ?? '').trim();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: 'Customer Details',
        subtitle: 'View customer information',
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () async {
              final saved = await context.push<Object?>(
                '/customers/edit?id=${customer.id}',
              );
              if (saved != null) {
                ref.invalidate(customerDetailProvider(customer.id));
                ref.invalidate(customerOrdersProvider(customer.id));
              }
            },
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _createOrder(context, ref),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Create Order'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SoftCard(
            radius: AppRadii.lg,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -36,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: -40,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary.withValues(alpha: 0.12),
                          ),
                          child: Center(
                            child: Text(
                              customer.name.trim().isEmpty
                                  ? '•'
                                  : customer.name
                                      .trim()
                                      .substring(0, 1)
                                      .toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name.displayTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: (customer.isActive
                                          ? AppColors.success
                                          : scheme.onSurfaceVariant)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: customer.isActive
                                            ? AppColors.success
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      customer.isActive
                                          ? 'Active Customer'
                                          : 'Inactive',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: customer.isActive
                                                ? AppColors.success
                                                : scheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      value: phone.isEmpty ? 'No phone' : phone,
                      muted: phone.isEmpty,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.mail_outline_rounded,
                      value: email.isEmpty ? 'No email' : email,
                      muted: email.isEmpty,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      value: 'Member since $memberSince',
                    ),
                    if (customer.outstandingBalancePaise > 0) ...[
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.account_balance_wallet_outlined,
                        value:
                            'Due ${Money(customer.outstandingBalancePaise).format(symbol: symbol)}',
                        accent: scheme.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          orders.when(
            loading: () => const SizedBox(
              height: 110,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => ErrorState(
              onRetry: () =>
                  ref.invalidate(customerOrdersProvider(customer.id)),
            ),
            data: (data) {
              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: HugeIcons.strokeRoundedShoppingCart01,
                      value: '${data.orderCount}',
                      label: 'Total Orders',
                      accent: scheme.primary,
                      background: scheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: HugeIcons.strokeRoundedMoney01,
                      value: Money(data.spentPaise).format(symbol: symbol),
                      label: 'Total Spent',
                      accent: AppColors.success,
                      background: AppColors.success.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 20,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'Latest orders from this customer',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  final name = customer.name.trim();
                  ref.read(salesSearchProvider.notifier).state = name;
                  context.go('/sales');
                },
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'View All',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
          ),
          const SizedBox(height: 12),
          orders.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (data) {
              if (data.recent.isEmpty) {
                return SoftCard(
                  radius: AppRadii.md,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  color: scheme.primary.withValues(alpha: 0.04),
                  borderColor: scheme.outline.withValues(alpha: 0.45),
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
                              const Color(0xFF7C3AED).withValues(alpha: 0.18),
                              scheme.primary.withValues(alpha: 0.08),
                            ],
                          ),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedInvoice01,
                            size: 32,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This customer has not placed any orders yet.\nStart billing to see history here.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // FilledButton.icon(
                      //   onPressed: () => _createOrder(context, ref),
                      //   icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                      //   label: const Text('Create Order'),
                      //   style: FilledButton.styleFrom(
                      //     minimumSize: const Size.fromHeight(46),
                      //     padding: const EdgeInsets.symmetric(horizontal: 20),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(14),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < data.recent.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _OrderHistoryCard(
                      invoice: data.recent[i],
                      symbol: symbol,
                      dateLabel: _date.format(
                        DateTime.fromMillisecondsSinceEpoch(
                          data.recent[i].createdAt,
                        ),
                      ),
                      status: _statusStyle(data.recent[i].status),
                      onTap: () =>
                          context.push('/invoice/${data.recent[i].id}'),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
    this.muted = false,
    this.accent,
  });

  final IconData icon;
  final String value;
  final bool muted;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = accent ?? scheme.primary;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: tone),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.background,
  });

  final List<List<dynamic>> icon;
  final String value;
  final String label;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      radius: AppRadii.md,
      color: background,
      borderColor: accent.withValues(alpha: 0.12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(icon: icon, size: 18, color: accent),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
          ),
        ],
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({
    required this.invoice,
    required this.symbol,
    required this.dateLabel,
    required this.status,
    required this.onTap,
  });

  final InvoiceSummary invoice;
  final String symbol;
  final String dateLabel;
  final ({Color color, String label}) status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final number = invoice.invoiceNumber.startsWith('#')
        ? invoice.invoiceNumber
        : invoice.invoiceNumber;

    return SoftCard(
      radius: AppRadii.md,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.more_horiz_rounded,
              color: status.color,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
