import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Unified image loader for local product/store files and any http(s) URLs.
///
/// Uses [CachedNetworkImage] for network URLs. Local files use [Image.file]
/// with decode cache size hints so list tiles do not keep full-resolution bitmaps.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.error,
  });

  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Decode width in physical pixels (defaults from layout size × devicePixelRatio).
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget? error;

  bool get _isNetwork {
    final p = path?.trim() ?? '';
    return p.startsWith('http://') || p.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final raw = path?.trim() ?? '';
    if (raw.isEmpty) {
      return placeholder ?? error ?? const SizedBox.shrink();
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = memCacheWidth ??
        (width != null ? (width! * dpr).round() : null);
    final cacheH = memCacheHeight ??
        (height != null ? (height! * dpr).round() : null);

    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: raw,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        placeholder: (_, _) =>
            placeholder ??
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        errorWidget: (_, _, _) =>
            error ??
            placeholder ??
            Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    final file = File(raw);
    if (!file.existsSync()) {
      return error ?? placeholder ?? const SizedBox.shrink();
    }

    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) =>
          error ??
          placeholder ??
          Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
