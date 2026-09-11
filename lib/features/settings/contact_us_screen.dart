import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
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
        showSnack(context, 'Unable to open link');
      }
    } catch (_) {
      if (context.mounted) showSnack(context, 'Unable to open link');
    }
  }

  Future<void> _call(BuildContext context) =>
      _open(context, Uri(scheme: 'tel', path: phoneE164));

  Future<void> _whatsApp(BuildContext context) {
    final uri = Uri.parse(
      'https://wa.me/917845456609?text=${Uri.encodeComponent(_helpMessage)}',
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              scheme.surface,
              scheme.surface,
            ],
            stops: const [0, 0.28, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: scheme.onSurface,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Contact us',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withValues(alpha: 0.18),
                            scheme.primary.withValues(alpha: 0.06),
                            scheme.surface,
                          ],
                        ),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.support_agent_rounded,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Need help?',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'If you have any doubts or need help with POS Billing, contact us anytime. We are happy to assist.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ContactTile(
                      icon: Icons.call_rounded,
                      iconColor: const Color(0xFF2563EB),
                      title: 'Mobile',
                      subtitle: phone,
                      onTap: () => _call(context),
                      onLongPress: () => _copy(context, phone, 'Mobile number'),
                    ),
                    const SizedBox(height: 10),
                    _ContactTile(
                      icon: LineIcons.whatSApp,
                      iconColor: const Color(0xFF25D366),
                      title: 'WhatsApp',
                      subtitle: 'Chat with us',
                      onTap: () => _whatsApp(context),
                    ),
                    const SizedBox(height: 10),
                    _ContactTile(
                      icon: Icons.mail_rounded,
                      iconColor: const Color(0xFFEA4335),
                      title: 'Email',
                      subtitle: email,
                      onTap: () => _mail(context),
                      onLongPress: () => _copy(context, email, 'Email'),
                    ),
                    const SizedBox(height: 10),
                    _ContactTile(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Address',
                      subtitle: address,
                      onTap: () => _maps(context),
                      onLongPress: () => _copy(context, address, 'Address'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
