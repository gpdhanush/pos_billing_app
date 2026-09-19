# POS Billing

Offline-first Point of Sale (POS) app for Android shops — billing, inventory, customers, expenses, reports, printer, and local/Drive backup.

## Features

- **Billing** — cart, barcode scan, discounts/tax, multi-payment (cash / UPI / card / credit)
- **Sales history** — invoice details, reprint, PDF share, refund / cancel
- **Products & categories** — catalog with cost/selling price, stock levels
- **Stock movements** — Stock History (All / IN / OUT), Stock IN with cost price (updates latest purchase cost), Stock OUT adjustments
- **Customers** — credit limit and outstanding balance
- **Expenses & reports** — period filters, PDF export
- **Printer** — Bluetooth ESC/POS test print / last bill
- **Backup** — encrypted local `.posbak` under **Downloads → POS Billing → backup** (+ optional Google Drive). Older backups can be deleted; the latest is protected.
- **Export data** — CSV / ZIP for products, orders, customers, stock ledger (Settings → Export data)
- **Security** — biometric app lock
- **Get Started** — home card until categories and products exist
- **Contact us** — phone, WhatsApp, email, address
- **Crash logs** — local diagnostics with device details; users can send logs to support

## Support

| Channel | Detail |
|---------|--------|
| Email | [agprakash406@gmail.com](mailto:agprakash406@gmail.com) |
| Phone / WhatsApp | 7845456609 |
| Address | Velachery, Chennai 600042 |

### Crash / diagnostic logs

Because the app works offline, crashes cannot be reported automatically. Errors are written to a local log file with **device details** (Android version, model, app version, locale, etc.).

Users can send logs from:

1. **Crash screen** → **Send crash log**
2. **Settings → About → Send app logs**

That opens the system share sheet with `pos_billing_crash.log` (choose Gmail / email and send to **agprakash406@gmail.com**). If sharing fails, a mailto draft with device summary is opened instead.

Log file path (app private storage): `Documents/logs/pos_billing_crash.log` (rotated around 512 KB).

## Tech stack

- Flutter + Riverpod + GoRouter
- SQLite (`sqflite`) — local-first data
- PDF / share (`pdf`, `share_plus`)
- Bluetooth thermal printing
- Google Sign-In + Drive (optional backup)
- `device_info_plus` / `package_info_plus` for diagnostics

## Getting started

```bash
flutter pub get
flutter run
```

Generate localizations after editing ARB files:

```bash
flutter gen-l10n
```

## Project layout

```
lib/
  app/           # theme, router, providers, localization
  core/          # database, services (backup, export, logs, printer), security
  features/      # screens (billing, sales, stock, settings, …)
  shared/        # models, widgets
packages/
  soft_ui_kit/   # portable theme + UI kit (pub.dev: soft_ui_kit)
```

To reuse this UI in another app, add [`soft_ui_kit`](https://pub.dev/packages/soft_ui_kit) and follow [`packages/soft_ui_kit/README.md`](packages/soft_ui_kit/README.md).

## Stock cost tip

When purchase cost changes (e.g. ₹13 → ₹17), use **Stock → + → Stock IN** with the new **Cost Price**. That records a purchase movement and updates the product’s latest cost. Do not only overwrite price on the product form if you need a history of costs.

## License

Private / proprietary — all rights reserved.
