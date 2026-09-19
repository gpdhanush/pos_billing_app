# soft_ui_kit

Material 3 Flutter UI kit: **SoftNavBar**, SoftCard, theme tokens, and onboarding widgets.

[![pub package](https://img.shields.io/pub/v/soft_ui_kit.svg)](https://pub.dev/packages/soft_ui_kit)

## Install

```yaml
dependencies:
  soft_ui_kit: ^1.0.0
```

```bash
flutter pub get
```

## SoftNavBar

```dart
import 'package:flutter/material.dart';
import 'package:soft_ui_kit/soft_ui_kit.dart';

class ShopShell extends StatefulWidget {
  const ShopShell({super.key});

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Home')),
      bottomNavigationBar: SoftNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          SoftNavItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          SoftNavItem(icon: Icon(Icons.history), label: 'History'),
          SoftNavItem(icon: Icon(Icons.point_of_sale_outlined), label: 'Billing'),
          SoftNavItem(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
          SoftNavItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
```

## Theme

```dart
import 'package:soft_ui_kit/soft_ui_kit.dart';

MaterialApp(
  theme: AppTheme.light(AccentOption.teal.seed),
  darkTheme: AppTheme.dark(AccentOption.teal.seed),
  themeMode: ThemeMode.system,
  builder: (context, child) => KeyboardDismissOnTap(
    child: child ?? const SizedBox.shrink(),
  ),
);
```

## Other widgets

`SoftCard`, `GlassPageHeader`, `SoftSearchField`, `SoftPeriodBadge`, `PrimaryCtaBar`, `EmptyState`, `AccentPicker`, `OnboardBackdrop`, `showConfirmBottomSheet`.

See the [example](example/) app.

## License

MIT. Arimo font is Apache 2.0.
