import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const phone = AppLinks.supportPhone;
  static const phoneE164 = AppLinks.supportPhoneE164;
  static const email = AppLinks.supportEmail;
  static const address = AppLinks.supportAddress;

  static const _helpMessage =
      'Hi, I need help with the POS Billing app.';

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showSnack(context, AppLocalizations.of(context).commonError);
      }
    } catch (_) {
      if (context.mounted) {
        showSnack(context, AppLocalizations.of(context).commonError);
      }
    }
  }

  Future<void> _call(BuildContext context) =>
      _open(context, Uri(scheme: 'tel', path: phoneE164));

  Future<void> _whatsApp(BuildContext context) {
    final uri = Uri.parse(
      'https://wa.me/${AppLinks.supportWhatsAppE164}'
      '?text=${Uri.encodeComponent(_helpMessage)}',
    );
    return _open(context, uri);
  }

  Future<void> _mail(BuildContext context) {
    final uri = Uri.parse(
      'mailto:$email'
      '?subject=${Uri.encodeComponent('POS Billing help')}'
      '&body=${Uri.encodeComponent(_helpMessage)}',
    );
    return _open(context, uri);
  }

  Future<void> _maps(BuildContext context) {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    return _open(context, uri);
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) showSnack(context, '$label copied');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(
        title: l10n.contactUsTitle,
        subtitle: l10n.contactUsSubtitle,
        height: 64,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFD6EBFF),
                              scheme.primary.withValues(alpha: 0.18),
                              const Color(0xFFEAF4FF),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -28,
                              top: -36,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 48,
                              bottom: -50,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(alpha: 0.10),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 18, 8, 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SUPPORT',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: scheme.primary,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.2,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Need help?',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.4,
                                                  color: const Color(0xFF0B1F3A),
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'If you have any doubts or need help with POS Billing, contact us anytime. We are happy to assist.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: const Color(0xFF4B5B70),
                                                  height: 1.35,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    flex: 5,
                                    child: Image.asset(
                                      'assets/img/customer-support.png',
                                      height: 148,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.bottomCenter,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ContactTile(
                      icon: Icons.call_rounded,
                      iconColor: const Color(0xFF2563EB),
                      title: l10n.contactMobile,
                      subtitle: phone,
                      onTap: () => _call(context),
                      onLongPress: () => _copy(context, phone, l10n.contactMobile),
                    ),
                    const SizedBox(height: 10),
                    _ContactTile(
                      icon: LineIcons.whatSApp,
                      iconColor: const Color(0xFF25D366),
                      title: l10n.contactWhatsApp,
                      subtitle: l10n.contactWhatsAppHint,
                      onTap: () => _whatsApp(context),
                    ),
                    const SizedBox(height: 10),
                    _ContactTile(
                      icon: Icons.mail_rounded,
                      iconColor: const Color(0xFFEA4335),
                      title: l10n.commonEmail,
                      subtitle: email,
                      onTap: () => _mail(context),
                      onLongPress: () => _copy(context, email, l10n.commonEmail),
                    ),
                    const SizedBox(height: 10),
                    _ContactTile(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: l10n.commonAddress,
                      subtitle: address,
                      onTap: () => _maps(context),
                      onLongPress: () =>
                          _copy(context, address, l10n.commonAddress),
                    ),
                  ],
                ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: scheme.onSurface.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }
}
