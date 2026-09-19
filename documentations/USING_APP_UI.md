# Using POS UI (`soft_ui_kit`) in another app

The reusable kit is **[soft_ui_kit](https://pub.dev/packages/soft_ui_kit)** (`SoftNavBar`, theme, cards). Source: [`packages/soft_ui_kit`](../packages/soft_ui_kit).

```yaml
dependencies:
  soft_ui_kit: ^1.0.0
```

```dart
import 'package:soft_ui_kit/soft_ui_kit.dart';
```

This POS app still uses the local path:

```yaml
dependencies:
  soft_ui_kit:
    path: packages/soft_ui_kit
```

POS-only wrappers (localized confirms, `MoneyField`) stay in `lib/shared/widgets/ui_kit.dart`.
