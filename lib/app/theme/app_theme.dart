import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AccentOption {
  red,
  pink,
  purple,
  deepPurple,
  indigo,
  blue,
  lightBlue,
  cyan,
  teal,
  green,
  lightGreen,
  lime,
  amber,
  orange,
  deepOrange,
  brown,
  blueGrey,
}

extension AccentOptionX on AccentOption {
  /// Exact Material shade used as the app primary (not a tonal seed remap).
  Color get seed {
    switch (this) {
      case AccentOption.red:
        return Colors.red.shade600;
      case AccentOption.pink:
        return Colors.pink.shade600;
      case AccentOption.purple:
        return Colors.purple.shade600;
      case AccentOption.deepPurple:
        return Colors.deepPurple.shade600;
      case AccentOption.indigo:
        return Colors.indigo.shade600;
      case AccentOption.blue:
        return Colors.blue.shade600;
      case AccentOption.lightBlue:
        return Colors.lightBlue.shade600;
      case AccentOption.cyan:
        return Colors.cyan.shade600;
      case AccentOption.teal:
        return Colors.teal.shade600;
      case AccentOption.green:
        return Colors.green.shade600;
      case AccentOption.lightGreen:
        return Colors.lightGreen.shade600;
      case AccentOption.lime:
        return Colors.lime.shade700;
      case AccentOption.amber:
        return Colors.amber.shade700;
      case AccentOption.orange:
        return Colors.orange.shade600;
      case AccentOption.deepOrange:
        return Colors.deepOrange.shade600;
      case AccentOption.brown:
        return Colors.brown.shade600;
      case AccentOption.blueGrey:
        return Colors.blueGrey.shade600;
    }
  }

  String get label {
    switch (this) {
      case AccentOption.red:
        return 'Red';
      case AccentOption.pink:
        return 'Pink';
      case AccentOption.purple:
        return 'Purple';
      case AccentOption.deepPurple:
        return 'Deep Purple';
      case AccentOption.indigo:
        return 'Indigo';
      case AccentOption.blue:
        return 'Blue';
      case AccentOption.lightBlue:
        return 'Light Blue';
      case AccentOption.cyan:
        return 'Cyan';
      case AccentOption.teal:
        return 'Teal';
      case AccentOption.green:
        return 'Green';
      case AccentOption.lightGreen:
        return 'Light Green';
      case AccentOption.lime:
        return 'Lime';
      case AccentOption.amber:
        return 'Amber';
      case AccentOption.orange:
        return 'Orange';
      case AccentOption.deepOrange:
        return 'Deep Orange';
      case AccentOption.brown:
        return 'Brown';
      case AccentOption.blueGrey:
        return 'Blue Grey';
    }
  }

  String get storageKey => name;

  static AccentOption fromStorage(String? value) {
    return AccentOption.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccentOption.teal,
    );
  }
}

class AppColors {
  static const ink = Color(0xFF0B1220);
  static const inkSoft = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const lineDark = Color(0xFF1E293B);
  static const canvas = Color(0xFFF3F5F8);
  static const canvasDark = Color(0xFF070B14);
  static const panel = Color(0xFFFFFFFF);
  static const panelDark = Color(0xFF0F172A);
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
}

class AppRadii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const pill = 999.0;

  /// Dense list / form controls only (customers, products, etc.).
  static const compact = 5.0;
}

class AppTheme {
  static ThemeData light(Color seed) => _build(seed, Brightness.light);

  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);

  static ThemeData _build(Color seed, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final onSeed = _onColor(seed);
    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: isLight ? AppColors.panel : AppColors.panelDark,
    );
    // Keep the chosen accent as the true primary (fromSeed shades it otherwise).
    final scheme = generated.copyWith(
      primary: seed,
      onPrimary: onSeed,
      secondary: seed,
      onSecondary: onSeed,
      primaryContainer: Color.lerp(
        seed,
        isLight ? Colors.white : Colors.black,
        isLight ? 0.84 : 0.72,
      )!,
      onPrimaryContainer: seed,
      secondaryContainer: Color.lerp(
        seed,
        isLight ? Colors.white : Colors.black,
        isLight ? 0.88 : 0.78,
      )!,
      onSecondaryContainer: seed,
      surfaceContainerLowest: isLight ? AppColors.canvas : AppColors.canvasDark,
      outline: isLight ? AppColors.line : AppColors.lineDark,
      outlineVariant: isLight
          ? const Color(0xFFEEF2F7)
          : const Color(0xFF1A2332),
      onSurface: isLight ? AppColors.ink : const Color(0xFFE2E8F0),
      onSurfaceVariant: isLight ? AppColors.muted : const Color(0xFF94A3B8),
    );

    final textTheme = _textTheme(isLight);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Arimo',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      canvasColor: scheme.surfaceContainerLowest,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withValues(alpha: 0.12),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.ink : const Color(0xFFE2E8F0),
        contentTextStyle: TextStyle(
          color: isLight ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        headerBackgroundColor: scheme.primary,
        headerForegroundColor: scheme.onPrimary,
        todayForegroundColor: WidgetStatePropertyAll(scheme.primary),
        todayBorder: BorderSide(color: scheme.primary),
        dayShape: const WidgetStatePropertyAll(CircleBorder()),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline;
        }),
      ),
    );
  }

  static TextTheme _textTheme(bool isLight) {
    final ink = isLight ? AppColors.ink : const Color(0xFFE2E8F0);
    final muted = isLight ? AppColors.muted : const Color(0xFF94A3B8);
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: ink,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: ink,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: ink,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ink,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
        height: 1.35,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ink,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ink,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ink,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: muted,
        height: 1.3,
      ),
    );
  }

  static Color _onColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : AppColors.ink;
  }
}
