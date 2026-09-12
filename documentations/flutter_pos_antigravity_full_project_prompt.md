# Flutter POS Billing App — Complete Project Specification

## 1. Project Overview

Build a production-quality **offline-first POS Billing & Inventory mobile application using Flutter**.

Primary target: Android mobile devices.

The application must allow a shop/business to:

- Complete first-time store/business setup
- Manage store details, address, GST and invoice settings
- Manage products and categories
- Add and adjust stock
- Scan barcodes and QR codes
- Create fast POS bills
- Manage cart items
- Apply discounts and taxes
- Accept Cash, UPI, Card, Credit and Mixed Payments
- Complete checkout
- Print bills using thermal printers
- Manage customers
- View sales history and reports
- Backup and restore data using Google Drive
- Work fully offline using local SQLite
- Support English and Tamil
- Support Light, Dark and System themes
- Allow configurable accent/theme colors
- Provide secure, reliable and user-friendly UX
- Maintain financial data integrity and audit history

Core principle:

> **Scan → Add → Checkout → Pay → Save → Print**

The application must remain usable for normal POS operations without an internet connection.

---

# 2. Product Principles

Follow these principles throughout development:

1. Offline-first.
2. SQLite is the local source of truth.
3. Internet must not be required for normal billing.
4. Never lose a completed sale because of printer or internet failure.
5. Use SQLite/database transactions for financial operations.
6. Keep the UI responsive on budget Android phones.
7. Separate UI, business logic, database and external services.
8. Do not put SQL directly inside UI widgets.
9. Do not hardcode UI strings.
10. Do not hardcode colors throughout the application.
11. Support localization from the beginning.
12. Use Material 3.
13. Make barcode scanning extremely fast.
14. Keep checkout simple and require minimum taps.
15. Never silently delete financial records.
16. Keep audit/history records.
17. Design the schema for safe future migrations.
18. Avoid unnecessary network dependencies.
19. Prefer maintained packages.
20. Do not create fake implementations and mark them complete.

---

# 3. Recommended Flutter Stack

Use current stable, maintained packages compatible with the selected Flutter/Dart version.

Recommended architecture:

- Flutter
- Dart
- Material 3
- Riverpod for state management
- GoRouter for navigation
- SQLite for local database
- Flutter localization with ARB files
- Maintained QR/barcode scanner package
- Maintained thermal printer package
- Google Drive API for backup/restore
- Secure storage for secrets/PIN-related data where appropriate

Before adding dependencies:

1. Inspect the existing `pubspec.yaml`.
2. Avoid duplicate packages.
3. Prefer stable maintained packages.
4. Check Android compatibility.
5. Keep integrations behind interfaces.

---

# 4. Architecture

Use:

```text
Presentation
    ↓
Riverpod Providers / Controllers
    ↓
Use Cases / Application Services
    ↓
Repositories
    ↓
DAO / Database Layer
    ↓
SQLite
```

External integrations:

```text
BarcodeScannerService
PrinterService
GoogleDriveBackupService
SecureStorageService
```

Business logic must not depend directly on concrete external packages.

Example:

```text
BillingScreen
    ↓
BillingController
    ↓
CheckoutUseCase
    ↓
SalesRepository
    ↓
SQLite
```

---

# 5. Project Folder Structure

Use feature-based architecture:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── theme_provider.dart
│   └── localization/
│       ├── app_en.arb
│       └── app_ta.arb
│
├── core/
│   ├── database/
│   │   ├── database.dart
│   │   ├── migrations/
│   │   ├── dao/
│   │   └── tables/
│   ├── errors/
│   ├── constants/
│   ├── utils/
│   ├── services/
│   └── security/
│
├── features/
│   ├── splash/
│   ├── onboarding/
│   ├── setup/
│   ├── auth/
│   ├── dashboard/
│   ├── billing/
│   ├── products/
│   ├── inventory/
│   ├── customers/
│   ├── payments/
│   ├── sales/
│   ├── reports/
│   ├── printer/
│   ├── backup/
│   └── settings/
│
└── shared/
    ├── widgets/
    ├── dialogs/
    ├── extensions/
    └── models/
```

Keep features independently maintainable.

---

# 6. Application Startup Flow

Implement:

```text
App Launch
    ↓
Splash Screen
    ↓
Initialize Flutter dependencies
    ↓
Initialize SQLite
    ↓
Run database migrations
    ↓
Load application settings
    ↓
Load store profile
    ↓
Check onboarding status
    ↓
Check authentication/PIN
    ↓
Dashboard
```

First installation:

```text
Splash
 ↓
Onboarding
 ↓
Language Selection
 ↓
Theme Selection
 ↓
Store Setup
 ↓
Optional Security/PIN Setup
 ↓
Dashboard
```

Existing user:

```text
Splash
 ↓
PIN/Login if enabled
 ↓
Dashboard
```

Do not make the splash screen unnecessarily long.

---

# 7. Splash Screen

Create a minimal professional splash screen.

Display:

- App logo
- App name
- Loading indicator only if necessary

The splash screen can initialize:

- SQLite
- migrations
- settings
- dependency/service initialization

Avoid unnecessary animation.

---

# 8. Onboarding

Create 3 onboarding pages.

## Page 1 — Fast Billing

Title:

```text
Fast & Simple Billing
```

Description:

```text
Scan products, manage your cart and complete bills in seconds.
```

## Page 2 — Inventory

Title:

```text
Know Your Stock
```

Description:

```text
Track purchases, stock movements and available inventory with ease.
```

## Page 3 — Backup

Title:

```text
Keep Your Data Safe
```

Description:

```text
Back up your POS data to Google Drive and restore it when needed.
```

Buttons:

```text
Skip
Next
Get Started
```

Store onboarding completion locally.

Do not show onboarding again unless the user resets onboarding/app data.

---

# 9. Language Support

Default language:

```text
English
```

Supported languages:

```text
English
Tamil
```

Use proper Flutter localization and ARB files.

Never hardcode user-facing strings throughout screens.

Use keys such as:

```text
app.title
dashboard.title
billing.new_bill
billing.checkout
billing.payment
billing.total
products.add_product
products.product_name
products.barcode
inventory.stock
settings.language
settings.theme
```

Provide natural, human-written Tamil translations suitable for Indian shop users.

Allow language switching from Settings.

Changing language should update the UI without restart wherever practical.

---

# 10. Theme System

Use Material 3.

Support:

```text
Light
Dark
System Default
```

Also support selectable accent colors.

Example:

```text
Blue
Green
Teal
Purple
Orange
```

Do not hardcode colors inside feature screens.

Use:

```dart
Theme.of(context).colorScheme
```

and theme extensions where appropriate.

Persist:

- theme mode
- selected accent color

in local settings.

Dark mode must be a properly designed dark theme, not simply inverted colors.

---

# 11. Initial Store / Business Setup

After onboarding, first-time users must complete a **Store Setup Wizard**.

Flow:

```text
Splash
 ↓
Onboarding
 ↓
Language
 ↓
Theme
 ↓
Store Setup
 ↓
Optional Security Setup
 ↓
Dashboard
```

The normal Dashboard should not be shown until the minimum required store setup is completed.

## Store Setup Wizard

Recommended steps:

```text
Step 1 → Store Details
Step 2 → Contact & Address
Step 3 → GST / Tax
Step 4 → Invoice Settings
Step 5 → Complete
```

Show a progress indicator.

Example:

```text
● Store    ○ Contact    ○ GST    ○ Invoice
```

The user can go back and edit previous steps.

---

# 12. Store Details

Fields:

```text
Store / Business Name *
Store Display Name
Business Logo
```

Store/business name is required.

Allow the user to select a logo from the device.

The logo can later appear on thermal receipts where supported.

---

# 13. Contact Details

Fields:

```text
Phone Number
Alternate Phone Number
Email Address
Website
```

Validate:

- Phone number format
- Email format
- Website format if entered

Do not make optional fields mandatory.

---

# 14. Address Details

Provide separate fields:

```text
Address Line 1
Address Line 2
Area / Locality
City
District
State
Country
PIN / Postal Code
```

Default country:

```text
India
```

Do not require GPS permission for store setup.

The user must be able to manually enter the address.

---

# 15. GST / Tax Setup

Provide:

```text
GST Registered?

Yes
No
```

If Yes:

```text
GSTIN *
Business Type
Default Tax Configuration
```

Validate GSTIN appropriately.

Do not force GSTIN for non-GST-registered businesses.

Business type may include:

```text
Regular
Composition
Other
```

Do not assume every product has the same tax rate.

Product-level tax configuration must remain available.

---

# 16. Invoice Settings

Allow:

```text
Invoice Prefix
Starting Invoice Number
Receipt Footer Message
```

Example:

```text
Invoice Prefix:
INV

Starting Number:
1

Receipt Footer:
Thank you for shopping with us!
```

Generate a receipt preview dynamically from store settings.

Never hardcode business information.

---

# 17. Store Database

Create a dedicated `stores` table.

Recommended fields:

```text
id
business_name
display_name
logo_path

address_line_1
address_line_2
area
city
district
state
country
postal_code

phone
alternate_phone
email
website

is_gst_registered
gstin
business_type
default_tax_rate

invoice_prefix
next_invoice_number
receipt_footer

currency_code
currency_symbol

is_setup_completed

created_at
updated_at
```

Do not store important business information only as an unstructured JSON blob in `settings`.

---

# 18. Store Repository

Create:

```text
StoreRepository
StoreController
StoreProvider
```

Responsibilities:

```text
loadStore()
createStore()
updateStore()
updateLogo()
completeSetup()
```

All features must obtain store information through the repository/provider.

Do not duplicate store information across features.

---

# 19. Store Setup Validation

Minimum required:

```text
Business Name
```

Optional:

```text
Address
Phone
GST
Email
Logo
Website
```

The user can complete optional information later.

If setup is incomplete, show a non-blocking profile completion reminder.

Example:

```text
Store Setup
75% complete

Complete your business profile
to improve your receipts.

[ Complete Setup ]
```

---

# 20. Edit Store Later

Everything from initial setup must be editable later:

```text
Settings
 ↓
Business Profile
 ├── Store Details
 ├── Contact Details
 ├── Address
 ├── GST / Tax
 └── Invoice Settings
```

Changes are stored locally in SQLite.

---

# 21. Dashboard

Create a modern, clean mobile POS dashboard.

Show:

```text
Good Morning 👋

Store Name

Today's Sales
₹24,580

Bills Today
48

Items in Stock
326

Low Stock
12
```

Quick actions:

```text
New Bill
Scan Product
Add Product
Add Stock
```

Recent bills:

```text
Invoice
Customer
Amount
Payment Status
Time
```

Do not run expensive queries on every widget rebuild.

Use optimized providers and SQLite aggregate queries.

---

# 22. Bottom Navigation

Recommended:

```text
Home
Billing
Stock
Sales
More
```

Billing must always be easy to access.

Use a visually prominent primary action for New Bill.

---

# 23. Product Management

## Product List

Support:

- Search
- Barcode search
- QR search
- Category filter
- Low-stock filter
- Out-of-stock filter
- Sorting
- Pagination/lazy loading

Display:

```text
Product Name
Barcode
Selling Price
Stock
Category
```

## Add/Edit Product

Fields:

```text
Product Name *
SKU
Barcode
QR Code
Category
Unit
Purchase Price
Selling Price
Tax/GST
Minimum Stock
Opening Stock
Product Image
```

Implement validation.

---

# 24. Product and Barcode Relationship

One product may have multiple barcodes.

Use:

```text
products
    ↓
product_barcodes
```

Scanning:

```text
Barcode
 ↓
product_barcodes
 ↓
product_id
 ↓
Product
```

Index barcode lookup.

---

# 25. Barcode / QR Scanner

Create a dedicated scanner screen:

```text
Scan Product

┌─────────────────┐
│                 │
│    SCAN AREA    │
│                 │
└─────────────────┘

Align barcode inside the frame

Flashlight

Enter Barcode Manually
```

After a successful scan:

```text
Scanner
 ↓
Find Product
 ↓
Product Found
 ↓
Immediately Add To Cart
```

Do not require unnecessary confirmation.

Prevent duplicate scan events with debounce/cooldown.

If not found:

```text
Product Not Found

Barcode: 8901234567890

[ Add Product ]
[ Enter Barcode ]
[ Cancel ]
```

Also architect the scanner layer so external Bluetooth/USB keyboard-style barcode scanners can be supported later.

---

# 26. POS Billing Screen

This is the most important screen.

Requirements:

- Fast barcode scanning
- Search product
- Manual product selection
- Cart
- Increase/decrease quantity
- Manual quantity entry
- Remove item
- Item discount
- Bill discount
- Tax
- Subtotal
- Grand total
- Customer selection
- Hold/resume bill if implemented
- Clear cart with confirmation

Recommended layout:

```text
New Bill
Invoice #1026

[ Search Product ]

[ Scan Barcode / QR ]

Cart

Product A
₹100
Qty 2
₹200

Product B
₹250
Qty 1
₹250

----------------

Subtotal       ₹450
Discount        ₹20
Tax             ₹21
----------------
TOTAL          ₹451

[ CHECKOUT ]
```

Checkout must remain easy to reach.

---

# 27. Cart Performance

Do not rebuild the entire billing screen when one item changes.

Use isolated state providers/controllers.

Example:

```text
CartProvider
CartItemProvider
CartTotalProvider
```

Only affected widgets should rebuild.

Use immutable state where appropriate.

---

# 28. Checkout

Display:

```text
Total Amount

₹451
```

Payment options:

```text
Cash
UPI
Card
Credit
Mixed Payment
```

Cash:

```text
Total
₹451

Received
₹500

Change
₹49
```

Complete:

```text
[ COMPLETE PAYMENT ]
```

After success:

```text
✓ Payment Successful

Invoice #1026

₹451

[ Print Bill ]

[ New Bill ]
```

---

# 29. Mixed Payment

Support split payments.

Example:

```text
Total: ₹1,250

Cash     ₹500
UPI      ₹750
----------------
Paid    ₹1,250
Balance     ₹0
```

Store each payment method as a separate payment record.

---

# 30. Credit Sales

For credit:

```text
Credit
 ↓
Select Customer
 ↓
Create Sale
 ↓
Outstanding Balance
```

Do not create anonymous credit sales without customer identification.

Maintain customer outstanding balance and payment history.

---

# 31. Database Design

Minimum tables:

```text
stores
users
categories
products
product_barcodes

stock_transactions

customers

invoices
invoice_items
payments

expenses

printers
settings

backup_history
audit_logs
```

Add tables only when required by business logic.

---

# 32. Product Table

Recommended:

```text
id
name
sku
category_id
unit
purchase_price
selling_price
tax_rate
minimum_stock
current_stock
image_path
is_active
created_at
updated_at
```

Avoid floating-point money errors.

Prefer integer minor currency units where appropriate.

Example:

```text
₹100.50 → 10050 paise
```

Centralize money calculations.

---

# 33. Stock Management

Do not rely only on:

```text
products.current_stock
```

Maintain stock transaction history.

Examples:

```text
PURCHASE     +20
SALE          -2
ADJUSTMENT    +5
SALE          -1
RETURN        +1
```

Recommended fields:

```text
id
product_id
transaction_type
quantity
reference_type
reference_id
unit_cost
note
created_at
created_by
```

Maintain `current_stock` for fast lookup, but record every movement.

---

# 34. Stock In

Flow:

```text
Scan Barcode
 ↓
Find Product
 ↓
Enter Quantity
 ↓
Purchase Price
 ↓
Tax/Discount if required
 ↓
Save
 ↓
Increase Current Stock
 ↓
Create Stock Transaction
```

Allow manual product selection as well.

---

# 35. Stock Adjustment

Require a reason.

Example:

```text
Adjustment

Product: Rice
Current Stock: 20
Adjustment: -2
Reason: Damaged stock

[ Save Adjustment ]
```

Create a stock transaction and audit log.

---

# 36. Invoice Tables

Use:

```text
invoices
invoice_items
payments
```

Invoice:

```text
id
invoice_number
customer_id
subtotal
discount
tax
total
status
created_at
updated_at
```

Invoice item:

```text
id
invoice_id
product_id
product_name_snapshot
barcode_snapshot
quantity
unit_price
discount
tax
total
```

Store historical product name and price snapshots so future product edits do not change old invoices.

---

# 37. Invoice Numbering

Use a local database sequence/counter.

Example:

```text
INV-2026-000001
INV-2026-000002
INV-2026-000003
```

Never rely only on timestamps.

Prevent duplicate invoice numbers.

Support configurable prefix and starting number.

---

# 38. Checkout Atomic Transaction

This is critical.

When completing a sale:

```text
BEGIN TRANSACTION

1. Validate cart
2. Validate stock
3. Generate invoice number
4. Insert invoice
5. Insert invoice items
6. Insert payment records
7. Update product stock
8. Insert stock transactions
9. Update customer balance if required
10. Insert audit log

COMMIT
```

If anything fails:

```text
ROLLBACK
```

Never allow partially completed financial transactions.

Invalid state that must never happen:

```text
Invoice created ✓
Payment created ✓
Stock update failed ✗
```

---

# 39. Money and Calculation Rules

Do not use ordinary floating-point arithmetic carelessly for financial calculations.

Use integer minor units where appropriate.

Create:

```text
BillingCalculationService
```

Responsibilities:

```text
calculateItemTotal()
calculateSubtotal()
calculateDiscount()
calculateTax()
calculateGrandTotal()
calculatePaidAmount()
calculateBalance()
calculateChange()
```

All invoice calculations must go through the same calculation service.

Do not duplicate calculation logic across screens.

Define rounding behavior centrally.

---

# 40. Thermal Printer Architecture

Create:

```text
PrinterService
```

Possible implementations:

```text
PrinterService
 ├── BluetoothPrinterService
 ├── UsbPrinterService
 └── NetworkPrinterService
```

Do not put printer-specific code inside BillingScreen.

Printer settings:

```text
Printer Name
Connection Type
Paper Size
Character Encoding
Test Print
```

Support common:

```text
58mm
80mm
```

Provide:

```text
Connect Printer
Disconnect
Test Print
Print Last Bill
```

---

# 41. Printing Flow

Important:

```text
Checkout
 ↓
Save Transaction Successfully
 ↓
Show Payment Success
 ↓
Print Receipt
```

Never depend on printing to determine whether the sale was successful.

If printing fails:

```text
Payment Successful

Unable to connect to printer.

[ Retry Print ]
[ Print Later ]
[ Done ]
```

The completed sale must remain saved.

Sales History must allow reprinting.

---

# 42. Receipt Content

Receipt should dynamically contain:

```text
Store Logo
Store Name
Address
Phone
Email
GSTIN if configured

Invoice Number
Date / Time

Items
Quantity
Price
Amount

Subtotal
Discount
Tax
Grand Total

Payment Method
Paid Amount
Balance / Change

Receipt Footer
```

Do not hardcode store information.

Make receipt formatting thermal-printer friendly.

---

# 43. Sales History

Provide:

```text
Today
Yesterday
This Week
This Month
Custom Date Range
```

Filters:

```text
Payment Method
Customer
Invoice Status
Date
```

Invoice details:

```text
Invoice
Customer
Items
Payment
Totals
```

Actions:

```text
Print
Reprint
Refund
Cancel if permitted
```

Do not directly delete completed financial records.

---

# 44. Refund and Cancellation

Do not simply delete an invoice.

For cancellation/refund:

```text
Original Sale
 ↓
Create reversal/refund record
 ↓
Return stock if applicable
 ↓
Create stock transaction
 ↓
Record payment reversal
 ↓
Audit log
```

Keep the original sale for auditability.

---

# 45. Customers

Fields:

```text
Name
Phone
Email
Address
Credit Limit
Opening Balance
Notes
```

Customer details:

```text
Purchase History
Outstanding Balance
Payments
```

Search by name or phone.

---

# 46. Reports

Useful reports:

```text
Today's Sales
Today's Bills
Cash Sales
UPI Sales
Card Sales
Credit Sales

Top Products
Low Stock
Out of Stock
Stock Value

Daily Sales
Weekly Sales
Monthly Sales
```

Use SQLite aggregation queries.

Do not load thousands of rows into Dart just to calculate totals.

---

# 47. Expenses

Provide an optional expense module:

```text
Expense
Category
Amount
Payment Method
Note
Date
```

Reports can show expenses separately from sales.

Do not mix expense records into sales records.

---

# 48. Audit Logs

Create:

```text
audit_logs
```

Track important actions:

```text
PRODUCT_CREATED
PRODUCT_UPDATED
PRICE_CHANGED
STOCK_ADJUSTED
SALE_CREATED
PAYMENT_RECEIVED
SALE_CANCELLED
REFUND_CREATED
BACKUP_CREATED
BACKUP_RESTORED
USER_LOGIN
SETTINGS_CHANGED
```

Fields:

```text
id
action
entity_type
entity_id
metadata
created_at
user_id
```

Do not store sensitive secrets in audit metadata.

---

# 49. Offline-First Behavior

The following must work without internet:

- Product search
- Barcode/QR scanning
- Add stock
- Stock adjustment
- Billing
- Checkout
- Payments
- Customer lookup
- Local reports
- Thermal printing
- Invoice history
- Store settings

Internet-dependent features:

- Google Drive authentication
- Google Drive backup
- Google Drive restore/download

Display offline state non-intrusively:

```text
Offline Mode

Your billing will continue normally.
```

Do not treat offline mode as an application error.

---

# 50. Google Drive Backup

Backup is not synchronization.

Initial version should use a reliable full-backup model.

Flow:

```text
SQLite
 ↓
Create backup package
 ↓
Encrypt
 ↓
Validate/checksum
 ↓
Upload to Google Drive
 ↓
Record backup metadata
```

Example:

```text
POS_Backup/
 └── Store/
      └── 2026/
           ├── backup_2026-09-11_190000
           ├── backup_2026-09-10_190000
           └── backup_2026-09-09_190000
```

Do not overwrite the only backup.

Keep multiple versions.

---

# 51. Backup Security

Backups contain business and financial data.

Implement:

- Encryption
- Backup version
- Database schema version
- Integrity/checksum
- Timestamp
- Store identifier
- App version

Do not put Google access tokens in backup files.

Do not delete local data after a failed backup.

---

# 52. Restore

Settings:

```text
Backup & Restore

[ Backup Now ]

Last Backup:
Today, 7:00 PM

[ View Backups ]

[ Restore Backup ]
```

Restore flow:

```text
Create Safety Backup
 ↓
Confirm Restore
 ↓
Download/Read Backup
 ↓
Validate Integrity
 ↓
Validate Schema Version
 ↓
Create/replace database safely
 ↓
Run Required Migrations
 ↓
Reinitialize repositories/providers
```

Never overwrite the current database before validating the backup.

---

# 53. Automatic Backup

Optional:

```text
Automatic Backup

OFF
Daily
Weekly
```

Perform automatic backup only when practical conditions allow it.

For example:

```text
Internet Available
+
Google Drive Connected
+
Background execution permitted
```

If automatic backup fails, the POS must continue normally.

---

# 54. Backup History

Maintain:

```text
backup_history
```

Fields may include:

```text
id
file_name
drive_file_id
backup_version
database_version
file_size
checksum
status
created_at
completed_at
error_message
```

Show users:

```text
Successful
Failed
In Progress
```

Do not expose technical errors unnecessarily.

---

# 55. Security

Provide optional:

```text
App Lock
PIN
Biometric if supported
```

Never store a plain-text PIN.

Use secure storage/hashing appropriate to the security design.

Do not make authentication unnecessarily complex for a single-store POS.

---

# 56. Settings

Organize Settings:

```text
Business
 ├── Store Details
 ├── Invoice Settings
 └── Tax Settings

POS
 ├── Billing
 ├── Payment
 └── Barcode Scanner

Printer
 ├── Printer
 ├── Paper Size
 └── Test Print

Appearance
 ├── Theme
 ├── Accent Color
 └── Language

Backup
 ├── Google Drive
 ├── Backup Now
 ├── Automatic Backup
 └── Restore

Security
 ├── App Lock
 ├── PIN
 └── Biometric

About
 ├── App Version
 ├── Privacy
 └── Open Source Licenses
```

---

# 57. UI/UX Design Direction

The design should be:

- Modern
- Clean
- Professional
- Friendly
- Fast
- Business-focused
- One-hand friendly

Avoid:

- Excessive gradients
- Excessive animations
- Huge decorative elements
- Complicated navigation
- Too many confirmation dialogs
- Tiny buttons
- Low contrast
- Excessive rounded cards
- Unnecessary information
- Long forms without grouping

Use Material 3 consistently.

---

# 58. Mobile Responsive Design

Support:

```text
Small Android phones
Normal Android phones
Large Android phones
Android tablets where practical
```

Avoid fixed dimensions where possible.

Use:

- SafeArea
- LayoutBuilder
- MediaQuery
- Flexible
- Expanded
- ListView.builder
- Slivers where appropriate

Ensure keyboard/input handling does not hide important buttons.

---

# 59. Accessibility

Ensure:

- Good contrast
- Comfortable touch targets
- Readable font sizes
- Clear labels
- Icon + text where useful
- Screen-reader semantics
- Tamil text renders correctly
- Dark mode remains readable
- Do not rely only on color for status

---

# 60. Loading, Empty and Error States

Every asynchronous feature must handle:

```text
Loading
Success
Empty
Error
```

Use:

- Skeleton/loading indicators where appropriate
- Progress indicators for long operations
- Friendly empty states
- Retry actions

Examples:

```text
No Products Yet

Add your first product to start
managing inventory.

[ Add Product ]
```

```text
No Sales Found

Try another date or filter.
```

```text
Something went wrong

We couldn't load your products.

[ Try Again ]
```

Never expose raw stack traces.

---

# 61. Error Handling

Centralize errors.

Handle:

```text
Database Error
Printer Error
Scanner Error
Backup Error
Google Drive Authentication Error
Validation Error
Insufficient Stock
Duplicate Barcode
Invalid GSTIN
Restore Error
```

User-facing messages must be understandable.

Technical logs should remain separate.

---

# 62. Product Search Performance

Search by:

```text
Product Name
SKU
Barcode
```

Use SQLite queries.

Do not load the entire database into Dart for filtering.

Use indexes and pagination.

Debounce text search.

---

# 63. Database Indexes

Create indexes for common operations:

```text
products.sku
products.name
products.is_active

product_barcodes.barcode

invoices.invoice_number
invoices.created_at
invoices.customer_id

invoice_items.invoice_id
invoice_items.product_id

payments.invoice_id
payments.payment_method

stock_transactions.product_id
stock_transactions.created_at
```

Use unique constraints where appropriate.

---

# 64. Database Migration System

Implement versioned database migrations from the first version.

Example:

```text
v1
 ├── stores
 ├── products
 ├── categories
 ├── invoices
 └── invoice_items

v2
 └── product_barcodes

v3
 └── payments

v4
 └── audit_logs

v5
 └── backup_history
```

Never destroy user data during normal upgrades.

Before major migration:

```text
Safety Backup
 ↓
Migration
 ↓
Validation
```

---

# 65. Future-Proof Store Model

Even if V1 supports one store per device, keep:

```text
stores
```

as a separate entity.

Where appropriate, use:

```text
store_id
```

on future business-related entities.

Do not build unnecessary multi-store UI in V1.

The schema should remain capable of supporting multi-store functionality later.

---

# 66. Data Safety

Never perform destructive operations casually.

Do not use:

```text
DROP DATABASE
```

during normal upgrades.

Never delete invoices just to correct a mistake.

Use:

- cancellation
- refund
- reversal
- audit records

Always preserve financial history.

---

# 67. Performance Requirements

The application should feel fast on budget Android phones.

Requirements:

- Avoid unnecessary widget rebuilds.
- Use lazy lists.
- Paginate large datasets.
- Index barcode lookups.
- Index product search fields.
- Debounce search.
- Avoid loading all products at startup.
- Avoid loading all sales into memory.
- Use SQLite aggregate queries.
- Cache small frequently used settings.
- Keep cart state lightweight.
- Use transactions for checkout.
- Avoid expensive operations in widget build.
- Keep UI thread responsive.
- Optimize product images.
- Dispose scanner/printer resources correctly.

Target experience:

```text
Scan Barcode
 ↓
Immediate Product Result
 ↓
Add To Cart
```

The billing experience should feel immediate.

---

# 68. State Management

Use Riverpod.

Separate:

```text
UI State
Business State
Database State
Service State
```

Possible controllers:

```text
BillingController
CartController
ProductSearchController
CheckoutController
InventoryController
PrinterController
BackupController
SettingsController
StoreController
CustomerController
SalesController
```

Avoid one global provider containing the entire application state.

---

# 69. Repository Pattern

Example:

```text
ProductRepository
 ├── getProducts()
 ├── getProductByBarcode()
 ├── createProduct()
 ├── updateProduct()
 └── deactivateProduct()
```

```text
SalesRepository
 ├── createSale()
 ├── getSales()
 ├── getInvoice()
 ├── cancelSale()
 └── createRefund()
```

```text
StockRepository
 ├── addStock()
 ├── adjustStock()
 ├── getStock()
 └── getStockHistory()
```

```text
BackupRepository
 ├── createBackup()
 ├── uploadBackup()
 ├── listBackups()
 └── restoreBackup()
```

---

# 70. Development Sample Data

During development, provide realistic sample/mock data.

Products:

```text
Rice 5kg
Milk 1L
Sugar 1kg
Cooking Oil 1L
Biscuits
Soap
Shampoo
```

Invoices:

```text
INV-2026-000001
INV-2026-000002
```

Do not connect to a production database during initial development.

Make sample data easy to remove or disable in production builds.

---

# 71. Development Sequence

## Phase 1 — Foundation

```text
Project Setup
Theme
Localization
Routing
Splash
Onboarding
Store Setup
Settings
```

## Phase 2 — Database

```text
SQLite
Database Models
Repositories
DAO
Migrations
Indexes
```

## Phase 3 — Products

```text
Categories
Products
Barcodes
QR
Search
Product Images
```

## Phase 4 — Inventory

```text
Stock In
Stock Transactions
Stock Adjustment
Low Stock
Out of Stock
```

## Phase 5 — POS

```text
Cart
Barcode Scanning
Billing Calculation
Customer Selection
Checkout
Payments
Mixed Payment
Credit
```

## Phase 6 — Printer

```text
Printer Service
Bluetooth Printer
Receipt Generator
58mm
80mm
Test Print
Reprint
Printer Error Handling
```

## Phase 7 — Sales

```text
Sales History
Invoice Details
Refund
Cancellation
Customer History
```

## Phase 8 — Reports

```text
Sales Reports
Payment Reports
Product Reports
Stock Reports
Expense Reports
```

## Phase 9 — Backup

```text
Google Authentication
Backup
Encryption
Checksum
Backup History
Restore
Safety Backup
```

## Phase 10 — Production Polish

```text
Testing
Performance Optimization
Accessibility
Error Handling
Migration Testing
Offline Testing
Dark Mode Testing
Tamil Testing
Printer Testing
Backup/Restore Testing
```

---

# 72. Testing Requirements

Create tests for critical business logic.

## Unit Tests

Test:

- Invoice calculation
- Tax calculation
- Discount calculation
- Mixed payment
- Cash change
- Credit balance
- Stock calculation
- Invoice numbering
- GST validation
- Backup validation
- Database migrations

## Integration Tests

Test:

```text
Create Product
 ↓
Add Stock
 ↓
Scan Product
 ↓
Create Bill
 ↓
Checkout
 ↓
Verify Invoice
 ↓
Verify Payment
 ↓
Verify Stock
```

Also test:

```text
Insufficient Stock
Printer Failure
Database Failure
Duplicate Barcode
Backup Failure
Restore Failure
Cancelled Sale
Refund
Mixed Payment
```

---

# 73. Offline Test

Explicitly test:

```text
Disable Internet
 ↓
Scan Product
 ↓
Create Bill
 ↓
Checkout
 ↓
Payment
 ↓
Print
```

Everything above must continue working.

Then:

```text
Enable Internet
 ↓
Google Drive Backup
```

---

# 74. Printer Test

Test:

- Printer discovery
- Connection
- Connection loss
- Test print
- 58mm receipt
- 80mm receipt
- Tamil receipt where printer encoding supports it
- Reprint
- Printer unavailable after successful payment

A printer failure must never delete or reverse a successful sale.

---

# 75. Backup/Restore Test

Test:

```text
Create Products
 ↓
Add Stock
 ↓
Create Sales
 ↓
Create Customers
 ↓
Create Payments
 ↓
Create Backup
 ↓
Clear/Test Environment
 ↓
Restore
 ↓
Verify All Data
```

Also test corrupted/incompatible backup handling.

---

# 76. First-Time User Experience

The first-time experience should be:

```text
Welcome
 ↓
Choose Language
 ↓
Choose Theme
 ↓
Set Up Your Store

Let's set up your store

Store Name *
[ ABC Supermarket ]

Address
[ 123 Main Road ]

City
[ Chennai ]

Phone
[ 9876543210 ]

GST Registered?
[ Yes / No ]

[ Continue ]

 ↓
Invoice Setup
 ↓
Optional Security Setup
 ↓
Ready!

Your POS is ready to use.

[ Start Billing ]
```

Keep setup quick and friendly.

A new user should be able to create their first bill within a few minutes.

---

# 77. Example POS Flow

```text
OPEN APP
    ↓
SPLASH
    ↓
LOGIN/PIN
    ↓
DASHBOARD
    ↓
NEW BILL
    ↓
SCAN BARCODE
    ↓
PRODUCT ADDED
    ↓
SCAN MORE
    ↓
CHECKOUT
    ↓
SELECT PAYMENT
    ↓
COMPLETE PAYMENT
    ↓
DATABASE TRANSACTION COMMITTED
    ↓
STOCK UPDATED
    ↓
PAYMENT SAVED
    ↓
PRINT RECEIPT
    ↓
NEW BILL
```

---

# 78. Critical Implementation Rules for Antigravity

Before implementing every major feature:

1. Inspect the existing project.
2. Do not unnecessarily rewrite working code.
3. Inspect `pubspec.yaml` before adding dependencies.
4. Use maintained packages.
5. Follow feature-based architecture.
6. Separate UI and business logic.
7. Reuse shared components.
8. Avoid duplicate models/services.
9. Run formatter.
10. Run static analysis.
11. Run tests.
12. Fix compilation errors.
13. Verify migrations.
14. Verify offline behavior.
15. Verify English/Tamil.
16. Verify light/dark themes.
17. Verify responsive layouts.
18. Verify database transactions.
19. Verify printer failure behavior.
20. Verify backup failure behavior.

Do not mark a feature as complete if only the UI is implemented.

If an external integration cannot be fully tested in the current development environment, create a clean production-ready interface and clearly isolate any environment-specific limitation.

---

# 79. Final Definition of Done

The application is complete only when:

- Splash works
- Onboarding works
- English works
- Tamil works
- Light theme works
- Dark theme works
- System theme works
- Accent color works
- Store setup works
- Store details can be edited
- Address works
- GST works
- Invoice settings work
- SQLite works
- Migrations work
- Products work
- Categories work
- Barcode works
- QR scanning works
- Stock In works
- Stock adjustment works
- Stock transactions are recorded
- Low-stock detection works
- POS cart works
- Discounts work
- Tax works
- Checkout works
- Cash payment works
- UPI payment works
- Card payment works
- Credit payment works
- Mixed payment works
- Invoice is saved atomically
- Stock is updated atomically
- Payment records are saved correctly
- Thermal printer abstraction works
- Printing failure does not lose the sale
- Reprint works
- Sales history works
- Refund/cancellation flow works
- Customer management works
- Reports work
- Expenses work if enabled
- Google Drive backup works
- Backup encryption works
- Restore works
- Backup history works
- Offline billing works
- Error states work
- Loading states work
- Empty states work
- Database indexes are implemented
- Critical business logic is tested
- No hardcoded UI strings
- No hardcoded theme colors in feature screens
- No destructive database migration
- No unnecessary network dependency
- Application remains responsive with a large product database

---

# 80. Final Product Goal

Build this as a real production-quality POS application, not a UI prototype.

The core user experience must be:

> **Open → Scan → Add → Checkout → Pay → Print**

The application must be:

- Fast
- Offline-first
- Reliable
- Modern
- Easy to learn
- Easy to maintain
- Safe for financial data
- Localization-ready
- Theme-ready
- Printer-ready
- Backup-ready
- Future-proof

SQLite is the local source of truth for the device.

Google Drive is used for backup and restore, not as the primary database.

Most importantly:

> **A shop must be able to continue selling even when the internet is unavailable.**
