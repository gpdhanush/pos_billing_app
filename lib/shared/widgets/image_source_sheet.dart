import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/theme/app_theme.dart';
import 'package:pos_billing/shared/widgets/ui_kit.dart';

enum ImageSourceAction { camera, gallery, remove }

/// Modern camera / gallery (optional remove) sheet used across the app.
Future<ImageSourceAction?> showImageSourceSheet(
  BuildContext context, {
  String title = 'Add photo',
  String subtitle = 'Choose how you want to add an image',
  bool showRemove = false,
  String removeLabel = 'Remove photo',
}) {
  dismissKeyboard();
  return showModalBottomSheet<ImageSourceAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ImageSourceSheet(
      title: title,
      subtitle: subtitle,
      showRemove: showRemove,
      removeLabel: removeLabel,
    ),
  );
}

/// Picks an image with options that reduce Android buffer lock warnings.
Future<XFile?> pickAppImage(ImageSource source) {
  return ImagePicker().pickImage(
    source: source,
    imageQuality: 80,
    maxWidth: 1280,
    maxHeight: 1280,
    requestFullMetadata: false,
  );
}

/// Shows the source sheet, then opens camera/gallery. Returns the file, or
/// `null` if cancelled. Throws nothing for remove — check [onRemove] instead.
Future<XFile?> showImagePickerFlow(
  BuildContext context, {
  String title = 'Add photo',
  String subtitle = 'Choose how you want to add an image',
  bool showRemove = false,
  String removeLabel = 'Remove photo',
  Future<void> Function()? onRemove,
}) async {
  final action = await showImageSourceSheet(
    context,
    title: title,
    subtitle: subtitle,
    showRemove: showRemove,
    removeLabel: removeLabel,
  );
  if (action == null) return null;
  if (action == ImageSourceAction.remove) {
    await onRemove?.call();
    return null;
  }
  final source = action == ImageSourceAction.camera
      ? ImageSource.camera
      : ImageSource.gallery;
  return pickAppImage(source);
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({
    required this.title,
    required this.subtitle,
    required this.showRemove,
    required this.removeLabel,
  });

  final String title;
  final String subtitle;
  final bool showRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outline.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _SourceTile(
                        label: l10n.commonCamera,
                        caption: l10n.storeLogoHint,
                        icon: HugeIcons.strokeRoundedCamera01,
                        accent: scheme.primary,
                        onTap: () => Navigator.pop(
                          context,
                          ImageSourceAction.camera,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceTile(
                        label: l10n.commonGallery,
                        caption: l10n.productsPhotoHint,
                        icon: HugeIcons.strokeRoundedImage01,
                        accent: const Color(0xFF2563EB),
                        onTap: () => Navigator.pop(
                          context,
                          ImageSourceAction.gallery,
                        ),
                      ),
                    ),
                  ],
                ),
                if (showRemove) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: scheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: InkWell(
                      onTap: () => Navigator.pop(
                        context,
                        ImageSourceAction.remove,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                removeLabel,
                                style: TextStyle(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.commonCancel,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.label,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String caption;
  final List<List<dynamic>> icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: HugeIcon(icon: icon, size: 26, color: accent),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
