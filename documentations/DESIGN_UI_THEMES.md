# POS Billing — Design, UI & Themes

Source of truth for how the Android POS app looks and behaves. Tokens and shared widgets live in the portable kit [`packages/soft_ui_kit`](../packages/soft_ui_kit) (`AppTheme`, `SoftCard`, `GlassPageHeader`, …). This POS app re-exports them from `lib/app/theme/app_theme.dart` and `lib/shared/widgets/ui_kit.dart`. Appearance is user-configurable (light / dark / system + 17 accents).

To reuse this UI in another Flutter app, add [`soft_ui_kit`](https://pub.dev/packages/soft_ui_kit) from pub.dev (see [`packages/soft_ui_kit/README.md`](../packages/soft_ui_kit/README.md)).

---

## 1. Product & design principles

POS Billing is an **offline-first Point of Sale** for small shops: billing, stock, customers, expenses, reports, Bluetooth printing, and encrypted backup.

The UI is built for a **shop counter on a phone**, not a desktop dashboard.

| Principle | What it means in the UI |
|---|---|
| **Fast at the counter** | Large tap targets (48–60px), quantity steppers, barcode scan within one tap of the cart |
| **Calm, not flashy** | Flat surfaces, 1px borders, no Material tint, very light shadows |
| **Accent is the brand** | One user-chosen primary color drives CTAs, selected states, icons, and charts |
| **Readable money** | Indian grouping (`₹1,23,456.78`), bold totals, primary-colored grand total |
| **Works in both languages** | English and Tamil; titles are short; labels wrap; no hardcoded English in chrome |
| **Shop-floor contrast** | Light canvas `#F3F5F8` or near-black `#070B14`; ink text, never gray-on-gray |

**Visual personality:** soft retail SaaS — rounded cards on a cool gray canvas, Material 3 without the default purple seed, Arimo as a compact grotesque.

---

## 2. Brand

| Asset | Path | Usage |
|---|---|---|
| App logo | `assets/img/logo.png` | Splash, More → About, fallback via `AppLogo` |
| Cash / UPI / Card / Credit | `assets/img/payments/*.png` | Checkout chips, invoice payment badges |
| Support illustration | `assets/img/customer-support.png` | Contact us |

**Logo treatment**

- Rounded square (`AppRadii.lg` = 20, splash uses 24)
- On splash: 106px logo inside a 118px frosted tile on the accent fill
- Fallback: `Icons.point_of_sale_rounded` on `primaryContainer`

**Tone of voice**

- Short verbs: Add, Scan, Continue, Complete, View all
- Shop language: Walk-in, Stock IN / OUT, Low stock, Bills today
- Destructive copy is explicit: “Delete everything”, “Hide from billing”

---

## 3. Color system

### 3.1 Neutral palette (`AppColors`)

These do **not** shift with the accent. They keep light and dark modes consistent.

| Token | Hex | Role |
|---|---|---|
| `ink` | `#0B1220` | Primary text (light) |
| `inkSoft` | `#334155` | Secondary ink (rarely used directly) |
| `muted` | `#64748B` | Captions, hints, unselected nav |
| `line` | `#E2E8F0` | Borders (light) |
| `lineDark` | `#1E293B` | Borders (dark) |
| `canvas` | `#F3F5F8` | Scaffold / page background (light) |
| `canvasDark` | `#070B14` | Scaffold (dark) |
| `panel` | `#FFFFFF` | Cards, sheets, inputs (light) |
| `panelDark` | `#0F172A` | Cards, sheets, inputs (dark) |
| `success` | `#059669` | Positive delta, stock IN, online toast |
| `warning` | `#D97706` | Low stock, refunded, export |
| `danger` | `#DC2626` | Errors, expenses, offline badge, logout |

### 3.2 Semantic mapping (ColorScheme)

Built with `ColorScheme.fromSeed`, then **overridden** so the chosen accent is the true primary (Material seed would otherwise remap it).

| Slot | Light | Dark |
|---|---|---|
| `primary` / `secondary` | Accent seed | Accent seed |
| `onPrimary` | White or `ink` (by luminance) | White or `ink` |
| `primaryContainer` | Accent × white 84% | Accent × black 72% |
| `surface` | `panel` `#FFFFFF` | `panelDark` `#0F172A` |
| `surfaceContainerLowest` | `canvas` `#F3F5F8` | `canvasDark` `#070B14` |
| `outline` | `line` `#E2E8F0` | `lineDark` `#1E293B` |
| `outlineVariant` | `#EEF2F7` | `#1A2332` |
| `onSurface` | `ink` `#0B1220` | `#E2E8F0` |
| `onSurfaceVariant` | `muted` `#64748B` | `#94A3B8` |
| `error` | Material error (aligned with `danger`) | Material error |

**Alpha recipes (used everywhere)**

| Use | Formula |
|---|---|
| Icon well / chip fill | `accent.withValues(alpha: 0.10–0.12)` |
| Selected card fill | `primary.withValues(alpha: 0.08)` |
| Card border | `outline.withValues(alpha: 0.70–0.75)` |
| Soft shadow | `onSurface.withValues(alpha: 0.04–0.06)` |
| CTA glow | `primary.withValues(alpha: 0.28)` |
| Disabled CTA | Opacity 0.55 on the whole bar |

### 3.3 Accent options (`AccentOption`)

Default: **Teal** (`Colors.teal.shade600`). Stored as the enum name (`teal`, `blue`, …).

All seeds are Material **shade 600**, except Lime and Amber (**shade 700**) so they stay readable as button fills.

| Key | Seed | Typical feel |
|---|---|---|
| `red` | `Colors.red.shade600` | Urgent / retail |
| `pink` | `Colors.pink.shade600` | Soft retail |
| `purple` | `Colors.purple.shade600` | Boutique |
| `deepPurple` | `Colors.deepPurple.shade600` | Premium |
| `indigo` | `Colors.indigo.shade600` | Trust |
| `blue` | `Colors.blue.shade600` | Default-adjacent |
| `lightBlue` | `Colors.lightBlue.shade600` | Airy |
| `cyan` | `Colors.cyan.shade600` | Fresh |
| **`teal` (default)** | `Colors.teal.shade600` | Shop / inventory |
| `green` | `Colors.green.shade600` | Growth |
| `lightGreen` | `Colors.lightGreen.shade600` | Organic |
| `lime` | `Colors.lime.shade700` | High-vis |
| `amber` | `Colors.amber.shade700` | Warm / gold |
| `orange` | `Colors.orange.shade600` | Energy |
| `deepOrange` | `Colors.deepOrange.shade600` | Food / spice |
| `brown` | `Colors.brown.shade600` | Traditional |
| `blueGrey` | `Colors.blueGrey.shade600` | Neutral professional |

Accent picker: 52px circles (onboarding) or 5-column grid (More sheet). Selected state: 3px `onSurface` ring + checkmark in `onPrimary`.

### 3.4 Theme modes

Stored in settings as `light` | `dark` | `system` (`ThemeMode`).

| Mode | Scaffold | Surface | Status bar |
|---|---|---|---|
| Light | `#F3F5F8` | White cards | Dark icons (`SystemUiOverlayStyle.dark`) |
| Dark | `#070B14` | `#0F172A` cards | Light icons |
| System | Follows OS | Follows OS | Follows brightness |

Splash is the exception: **full accent fill**, `onPrimary` type, regardless of theme.

### 3.5 Fixed functional colors (do not recolor with accent)

| Signal | Color | Where |
|---|---|---|
| Success / online | `#059669` | Connectivity toast, week-over-week up, Add product chip |
| Warning | `#D97706` | Low stock, refunded invoices |
| Danger / offline | `#DC2626` | Offline pill, expenses, destructive confirms |
| Violet utility | `#7C3AED` | Categories, stock cell, printer row (not the user accent) |
| Blue utility | `#3B82F6` | Theme → Light option in More |
| Indigo utility | `#6366F1` | Theme → Dark option |
| Pink support | `#DB2777` | Help / Contact |

---

## 4. Typography

**Family:** Arimo (Google Fonts, SIL OFL) — Regular 400, Medium 500, SemiBold 600, Bold 700, plus italics. Declared in `pubspec.yaml`, applied as `fontFamily: 'Arimo'` on `ThemeData`.

Arimo is a compact Arial-metric grotesque: dense tables, Tamil + English, and receipt-like numbers without a second display font.

### 4.1 Scale (`AppTheme._textTheme`)

| Style | Size | Weight | Tracking | Line height | Use |
|---|---|---|---|---|---|
| `displaySmall` | 36 | 700 | −0.8 | 1.15 | Checkout grand total |
| `headlineMedium` | 28 | 700 | −0.5 | 1.20 | Onboarding titles |
| `headlineSmall` | 22 | 700 | −0.3 | 1.25 | Store name on Home, confirm titles |
| `titleLarge` | 18 | 700 | 0 | 1.30 | Page titles, empty-state titles |
| `titleMedium` | 16 | 600 | 0 | 1.35 | Section titles, list primary |
| `titleSmall` | 14 | 600 | 0 | 1.35 | Rows, button labels |
| `bodyLarge` | 16 | 500 | 0 | 1.45 | Subtitles, onboarding body |
| `bodyMedium` | 14 | 500 | 0 | 1.45 | Default copy |
| `bodySmall` | 12 | 500 | 0 | 1.40 | Muted captions |
| `labelLarge` | 13 | 600 | 0 | 1.30 | Chips, field labels |
| `labelMedium` | 12 | 600 | 0 | 1.30 | Period badges, meta |
| `labelSmall` | 11 | 600 | 0 | 1.30 | Nav labels, chart days |

**Weight extra-bold (800)** is applied locally on Home / More headers (`fontWeight: FontWeight.w800`). Arimo’s bold face is used; do not introduce a heavier file.

### 4.2 Type rules

- Page titles: `titleLarge` + w700, left-aligned (never centered AppBars)
- Money: always Indian grouping, 2 decimals, store currency symbol (default `₹`)
- Store name on Home: **uppercase**
- Nav labels: 11px, w700 selected / w500 idle
- Offline ribbon: 10px, w800, letter-spacing 0.4, uppercase
- Title-case user input (shop name, product name) via `TitleCaseTextFormatter` / `displayTitle`
- SKU / invoice prefix: uppercase via `UpperCaseTextFormatter`

---

## 5. Layout tokens

### 5.1 Radii (`AppRadii`)

| Token | Value | Use |
|---|---|---|
| `compact` | 5 | Dense list/search fields, product form |
| `sm` | 12 | Chips, small wells, snackbars |
| `md` | 16 | Buttons, inputs, FABs, list cards |
| `lg` | 20 | Default `SoftCard`, dialogs, date picker |
| `xl` | 24 | Bottom nav capsule, sheets, primary CTA bar |
| `pill` | 999 | Period badges, progress bar, accent chips |

### 5.2 Spacing (observed, not a class)

| Step | px | Typical |
|---|---|---|
| Tight | 4–6 | Icon-to-label, badge padding |
| Default | 8–12 | Card inner, list gaps |
| Section | 16–20 | Page horizontal padding (`16` lists, `20` Home/More) |
| Block | 22–28 | Between Home sections, onboarding blocks |
| Bottom | 28–32 | Scroll padding above nav / FAB |

**Page padding**

- Shell lists: `16` horizontal
- Home / More: `20` horizontal
- Onboarding / setup: `24–28` horizontal
- Empty states: `40` horizontal

### 5.3 Elevation & shadow

No Material elevation on cards, app bars, or inputs (`elevation: 0`, `surfaceTintColor: transparent`).

| Element | Shadow |
|---|---|
| `SoftCard` | `blur 16`, `offset (0, 6)`, 4% onSurface |
| Bottom nav capsule | `blur 24`, `offset (0, 10)`, 6% onSurface |
| `PrimaryCtaBar` | `blur 18`, `offset (0, 8)`, 28% primary |
| Connectivity toast | `blur 16`, `offset (0, 6)`, 35% success/danger |
| Filled quick-action icon | `blur 12`, `offset (0, 6)`, 28% accent |
| FAB | elevation 2 (the only Material elevation) |

### 5.4 Sizing

| Element | Size |
|---|---|
| Filled / outlined button min height | 52 |
| Compact filled (inventory bar, billing add) | 48–50 |
| `PrimaryCtaBar` | 60 |
| Onboarding primary | 56 × full width |
| Search field | 44 tall |
| Quantity stepper buttons | 34 × 34 |
| Icon wells (list / More) | 44 × 44, radius 12 |
| Overview icon wells | 34 × 34, radius 10 |
| Initials avatar | 36 default, 44 on billing customer |
| Bottom nav capsule | 72 tall, 16/4/16/8 padding |
| Glass header | 56–64 + status bar inset |
| Product thumb in cart | 52 × 52, radius 14 |
| Accent swatch | 52 (onboarding) |

---

## 6. Iconography

Two families, used together:

| Family | Package | Role |
|---|---|---|
| **Hugeicons** (stroke) | `hugeicons` | Home, More, onboarding, sales status, settings rows |
| **Material rounded** | Flutter SDK | AppBar back, scan, add, steppers, FABs, billing |
| **Line Icons** | `line_icons` | Bottom nav only (`LineIcons.home`, `history`, `cashRegister`, `boxes`, `horizontalEllipsis`) |

**Stroke Hugeicons** are the modern face of the product. Nav stays Line Icons so the five-tab bar is optically even.

**Icon well recipe** (copy this, don’t invent new ones)

```
44×44 (or 34×34 for stats)
background: accent @ 12%
radius: 12 (or 10)
icon: 20px (or 17px), accent color, no fill
```

**Status icons**

| Status | Icon | Color |
|---|---|---|
| Completed invoice | `strokeRoundedInvoice01` | primary |
| Refunded | `strokeRoundedReload` | warning |
| Cancelled | `strokeRoundedCancel01` | danger |
| Low stock | `strokeRoundedAlert02` | warning |
| Online | `Icons.wifi_rounded` | white on success |
| Offline | `Icons.cloud_off_rounded` / `wifi_off_rounded` | white on danger |

---

## 7. Component library

All of these are in `ui_kit.dart` unless noted.

### 7.1 Surfaces

**`SoftCard`** — default content container.

- Fill: `scheme.surface`
- Border: `outline @ 75%`
- Radius: `lg` (20); Home/More often override to `md` (16)
- Padding: 14 × 12
- Optional `InkWell` for tap / long-press
- Use for: list rows, overview grids, settings groups, cart, totals

**`GlassPageHeader`** — standard inner-page app bar.

- 92% `surfaceContainerLowest`, no elevation, no divider
- Left-aligned title (`titleLarge` w700) + optional subtitle (`labelMedium`)
- Height 56–64 plus status-bar padding
- Leading: `Icons.arrow_back_rounded` when `canPop`
- Used on almost every pushed route

**`OnboardBackdrop`** — setup-only gradient.

```
primary @ 8%  →  canvas  →  secondary @ 5%
topLeft → bottomRight
```

### 7.2 Actions

| Component | When |
|---|---|
| `FilledButton` | Primary page action (Save, Complete, Add product) |
| `OutlinedButton` | Secondary (History, Cancel in a pair) |
| `TextButton` | Inline “View all”, Skip, header actions |
| `FilledButton.tonal` | Compact “Add / Change” on a card |
| `FloatingActionButton.extended` | Catalog create (Products, Customers) |
| `PrimaryCtaBar` | Gradient 60px bar with trailing amount + arrow (checkout / pay) |
| `OnboardPrimaryButton` | Full-width 56px setup continue |

**Primary CTA gradient:** `primary → lerp(primary, secondary, 0.35)`, left to right, radius `xl`.

**Button pair in confirms:** Outlined Cancel (48h) + Filled Confirm (48h), 12px gap, equal width.

### 7.3 Inputs

- Filled white/dark panel, radius `md`, 16 × 14 padding
- Hint is the label (`floatingLabelBehavior: never`) — no floating labels
- Focus ring: primary, 1.5px
- Search: `SoftSearchField`, 44h, radius `compact` (5), leading search icon
- Money: `MoneyField` / prefix `₹ ` + `ThousandDecimalFormatter`
- Dense product form: `_fieldRadius = 5`

### 7.4 Selection & filters

**`SoftPeriodBadge`** — pill filter (Today / This week / All / Low stock).

- Selected: filled primary, 12 × 8 padding
- Idle: outlined surface, same padding
- Horizontal scroller, 8px trailing gap

**`SoftInfoBadge`** — non-interactive pill (e.g. “Today”). Primary @ 12% fill.

**`ChoiceChip`** — payment method on checkout, with PNG avatar.

**`OnboardOptionCard`** — selectable row for language / theme / permissions. Selected = primary border 1.6px + 8% fill.

### 7.5 Feedback

| Pattern | Spec |
|---|---|
| `EmptyState` | 88px gradient circle + title w800 + 3-line subtitle + optional filled action |
| `ErrorState` | Same, error icon, Retry |
| Snackbar | Floating, ink/slate fill, radius `sm` |
| Connectivity toast | Full-width top banner, success or danger fill, 280ms slide |
| Offline pill | Top-right, danger, pill, `OFFLINE` 10px |
| Confirm | Modal sheet (not a dialog): drag pill, 64px icon circle, title, body, two buttons |
| Crash page | Centered, max width 420, same empty-state circle, Retry / Home / Send logs |

**Destructive confirms** swap the filled button to `scheme.error`.

### 7.6 Domain widgets

| Widget | Role |
|---|---|
| `InitialsAvatar` | Customer / walk-in, primary @ 10% fill |
| `QtyStepper` | − count + ; plus is filled primary |
| `StatTile` | Icon + label + value on a SoftCard (legacy; Home uses overview cells) |
| `IconBadge` | Generic tinted well |
| `SoftQuickAction` | Filled/outlined chip with icon |
| `PaymentMethodIcon` | Cash / UPI / Card / Credit PNG |
| `AppLogo` | Brand mark |
| `AppImage` | Cached local/network product photo |

### 7.7 Charts (Home only)

7-day sales: 110px bar row. Today’s bar uses primary → `#38BDF8` gradient; other days are primary at 18–42% alpha. Radius 10. Delta pill: success/danger @ 12%.

---

## 8. Navigation & information architecture

### 8.1 Bottom shell (5 tabs)

Floating **capsule** above the home indicator — not a full-width Material `NavigationBar`.

```
┌──────────────────────────────────────────┐
│  Home    History    Billing    Stock   More  │
└──────────────────────────────────────────┘
     16px inset · 72px tall · radius 24
```

| Index | Route | Label | Icon |
|---|---|---|---|
| 0 | `/home` | Home | `LineIcons.home` |
| 1 | `/sales` | History | `LineIcons.history` |
| 2 | `/billing` | Billing | `LineIcons.cashRegister` |
| 3 | `/stock` | Stock | `LineIcons.boxes` |
| 4 | `/more` | More | `LineIcons.horizontalEllipsis` |

Selected: primary color, w700. Idle: `onSurfaceVariant`, w500. Icon 26px.

**Back behavior:** non-Home tab → Home; Home → exit sheet. Leaving Billing with a cart asks to discard.

### 8.2 Flows outside the shell

```
Splash (accent)
  → Permissions (if needed)
  → Onboarding (3 pages)
      → Language → Theme → Store setup → Security → Google connect
  → Home

Lock (biometric) overlays the shell when enabled.
```

Pushed routes (products, customers, reports, expenses, printer, backup, invoice, checkout, scan) sit on the root navigator with `GlassPageHeader`.

### 8.3 Screen templates

**A. Home dashboard** — greeting + store name, no app bar. Slivers, 20px gutters, pull-to-refresh.

**B. Filter list** — Glass header, search, period badges, `SoftCard` rows, optional FAB.

Used by: Sales, Products, Customers, Expenses, Stock, Notifications.

**C. Form** — Glass header, `ListView` of fields (often inside SoftCards), sticky Save as `FilledButton` or bottom bar.

**D. Setup** — `OnboardBackdrop`, hero icon, headline, option cards, full-width continue.

**E. Detail** — Glass header, hero card (total / photo), grouped SoftCards, bottom action bar (Print / Share / Refund).

---

## 9. Screen-by-screen UI notes

### Splash

- Full `scheme.primary` canvas
- Logo tile 118px, white 16% fill, 22% white border
- Title `headlineMedium` onPrimary, tagline `bodyLarge` at 85%
- Pill progress 6px + percent + `v1.0.0`

### Onboarding (3 pages)

Hero: 120px pulsing circle, primary → secondary gradient, 28px glow. Pages: Fast billing → Stock → Backup. Dots: 28×8 selected, 8×8 idle.

### Home

1. Greeting with time-of-day emoji (☀️ / 🌤 / 🌙) + **UPPERCASE store name**
2. Notification round button (primary @ 8%)
3. Today overview — 3-cell SoftCard (Bills / Stock / Low stock)
4. Week sales chart
5. Store-setup reminder (progress) and Get-started catalog card if empty
6. Quick actions — 4 icon columns (Add product filled success; Category violet; Expense danger; Customer primary)
7. Recent bills list

### Billing (counter)

Customer SoftCard → Add product + scan → cart list (thumbs, name, stepper, line total) → totals + `PrimaryCtaBar` to order checkout.

Empty cart: basket icon 42px + two lines of copy, not the full EmptyState.

### Checkout / Payment

1. Order review (`/checkout`) — invoice number as title, lines, discount/tax, pay bar
2. Payment (`/payment`) — giant primary total, method chips with PNGs, received + change well, Complete

### History (Sales)

Search + Today / Yesterday / Week / Month. Row: status icon well, invoice #, customer, time, amount, payment icons.

### Stock

Search + category sheet + low-stock toggle. Bottom dual buttons: Add product | History. Movement form for Stock IN (with cost) / Stock OUT.

### More

Grouped SoftCards: Shop, Business, Data, Support, Preferences, Appearance, About, Danger zone. Each row = 44px tinted well + title w800 + subtitle + chevron / value / switch.

Appearance: theme sheet, 5-column accent grid, language sheet.

### Reports

Period badges + custom date range (`showAppDatePicker`), KPI SoftCards, payment mix, top products, PDF export.

### Lock / Security

Onboarding-style backdrop, logo, biometric CTA. PIN UI remains in code paths but is no longer offered.

---

## 10. Motion

Keep motion short and functional.

| Interaction | Duration | Curve |
|---|---|---|
| Onboarding page | 380ms | `easeOutCubic` |
| Back page | 320ms | `easeOutCubic` |
| Option card / accent scale | 180–220ms | `easeOutCubic` |
| Page dots | 280ms | `easeOutCubic` |
| Hero icon pulse | 2200ms reverse | `easeInOut` |
| Chart bars | 420ms | `easeOutCubic` |
| Connectivity toast in | 280ms | `easeOutCubic` |
| Toast fade | 220ms | default |
| Toast visible | 2600ms | — |
| Splash progress | 1400ms | — |

Do not add hero-route transitions or parallax. `go_router` defaults are enough.

---

## 11. Content, locale & numbers

- Locales: `en`, `ta` (`intl` + generated `AppLocalizations`)
- Dates: `dd MMM yyyy, hh:mm a` (lists), `dd MMM yyyy` (ranges)
- Currency: store symbol, Indian grouping, 2 decimals
- Invoice: `{PREFIX}-{YEAR}-{000001}`
- Rounding at payment: 0.25 rupee threshold (`roundPaiseToRupeeAt25`)

**Don’t** concatenate untranslated English into chrome. Filter subtitles that are still hardcoded (e.g. product deactivate body) should move to ARB when touched.

---

## 12. Accessibility & density

- Min tap height 48px on primary actions; nav items are full-height 72px columns
- `KeyboardDismissOnTap` wraps the app; CTAs call `dismissKeyboardAnd`
- Contrast: ink on canvas (light) and `#E2E8F0` on `#070B14` (dark); never put muted on outlineVariant
- Accent-on-primary text uses luminance (`ThemeData.estimateBrightnessForColor`) so lime/amber stay dark-ink, red/teal stay white
- Switch: selected track = primary, thumb = onPrimary
- Semantic labels: `tooltip` on scan / icon-only buttons

This is a **phone-first, standard density** app (`VisualDensity.standard`). Do not switch to compact desktop density.

---

## 13. Do / don’t

**Do**

- Put new list/detail screens on `surfaceContainerLowest` with `GlassPageHeader` + `SoftCard`
- Tint icon wells with a **functional** color (success / warning / danger / violet) or `scheme.primary`
- Use Hugeicons for new settings / dashboard glyphs; Material rounded for back / add / scan
- Filter with `SoftPeriodBadge`, search with `SoftSearchField`
- Confirm destructive work with `showConfirmBottomSheet(..., destructive: true)`

**Don’t**

- Use `ColorScheme.fromSeed` primary without the override (it won’t match the swatch the user picked)
- Add Material `surfaceTint` or card elevation
- Center app-bar titles
- Introduce a second font
- Recolor success / warning / danger with the accent
- Build a second bottom nav — always the capsule in `AppShell`
- Drop floating labels back onto inputs

---

## 14. Implementation map

| Concern | File |
|---|---|
| Portable kit (use this in another app) | `packages/soft_ui_kit` (pub.dev: `soft_ui_kit`) |
| Tokens, ColorScheme, component themes | `packages/soft_ui_kit/lib/src/theme/app_theme.dart` (re-exported by `lib/app/theme/app_theme.dart`) |
| ThemeMode + accent wiring | `lib/app/app.dart` |
| Shared widgets | `packages/soft_ui_kit/lib/src/widgets/` (POS wrappers in `lib/shared/widgets/ui_kit.dart`) |
| Onboarding visuals | `packages/soft_ui_kit/lib/src/widgets/onboarding.dart` |
| Theme / accent picker (setup) | `lib/features/onboarding/language_screen.dart` (`ThemePickerScreen`) |
| Theme / accent picker (app) | `lib/features/more/more_screen.dart` |
| Bottom nav | `lib/features/shell/app_shell.dart` |
| Routes | `lib/app/router/app_router.dart` |
| Logo / payment art | `lib/core/constants/app_assets.dart` |
| Fonts | `packages/soft_ui_kit/fonts/Arimo/` (POS PDF still uses `assets/fonts/Arimo/`) |
| Settings keys | `lib/core/constants/app_constants.dart` (`theme_mode`, `accent_color`) |

---

## 15. Light vs dark snapshot

**Light** — cool gray canvas, white bordered cards, slate captions, accent only on actions and selected glyphs. Feels like a paper invoice on a shop counter.

**Dark** — near-black canvas `#070B14`, slate panels `#0F172A`, hairline `#1E293B` borders, body text `#E2E8F0`, muted `#94A3B8`. Same radii and type. Accent still the only saturated fill.

Both modes share one component set; never fork layouts per brightness.
