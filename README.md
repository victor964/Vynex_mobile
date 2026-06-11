# Vynex Mobile V1

**Offline business management for small-scale traders on Android.**

Vynex V1 is a complete, production-ready Flutter app that helps traders record purchases, track sales and profit, manage customer debts, and view business reports, all without internet, cloud accounts, or backend servers. Data is stored locally in SQLite on the device.

This repository preserves **Vynex V1.0.0** as a stable baseline. Future work (Vynex V2) continues from this codebase; use the `v1.0.0` Git tag to return to this exact release at any time.

---

## V1 at a glance

| | |
|---|---|
| **Version** | 1.0.0 (build 1) |
| **Platform** | Android (API 21 to 36) |
| **Package** | `com.vynex.vynex` |
| **Connectivity** | Fully offline |
| **Database** | SQLite (sqflite), schema version 3 |
| **State management** | Provider |
| **Navigation** | GoRouter |

---

## What V1 includes

### Authentication
- 4-digit PIN login with SHA-256 hashed storage
- Session persistence across app restarts
- First-launch PIN change flow
- Lock app from dashboard or settings

### Dashboard
- Live stats: total purchases, sales, profit, pending debts
- This month summary (revenue, profit, spent)
- Recent sales and purchases
- Quick actions to add purchase or sale
- Pull to refresh

### Purchases
- Full CRUD (create, read, update, delete)
- Auto total cost (quantity x cost price)
- Date backdating via date picker
- Optional notes
- List view with search and month filter
- Scrollable table view with row actions
- Delete confirmation dialog

### Sales
- Full CRUD with sale detail screen
- Product and service sale types
- Payment methods: Cash, M-Pesa, Paybill
- Auto profit and revenue calculation
- Loss warning when selling below cost
- Fully paid vs not fully paid toggle
- Automatic debt creation for unpaid sales
- Initial payment on credit sales
- Installment tracking and payment history
- Date backdating

### Debt tracker
- Pending and Cleared tabs
- Summary: total owed, collected, balance
- Badge on bottom navigation for pending count
- Debt detail with linked sale info
- Record partial payments (today's amount)
- Client name updates
- Mark as fully cleared
- Auto-clear when balance reaches zero

### Reports
- Period filters: Today, Last 7 Days, This Month, Custom range
- Payment method and sale type filters
- Six summary stat cards per period
- Daily revenue vs profit line chart
- Monthly overview bar chart (last 6 months)
- Top performing items table
- Insight strip (best seller, profitability)
- Export sales, purchases, and debts to Excel
- Share exports via WhatsApp, Telegram, and other apps

### Settings
- Business profile (name, owner, phone, currency, tagline)
- Live preview card
- Change PIN
- Full database backup and restore
- Reset business profile to defaults
- Lock app

### Polish (V1 release)
- Custom gold-on-black app icon and splash screen
- Gold and black Vynex theme throughout
- Empty, loading, and error states on all modules
- Haptic feedback on key actions
- Pull to refresh on list screens
- Release-signed APK build support

---

## Tech stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (Dart, null-safe) |
| State | Provider |
| Database | sqflite + path_provider |
| Navigation | go_router |
| Charts | fl_chart |
| Export | excel, share_plus |
| Auth | crypto (SHA-256), shared_preferences |
| Restore | file_picker |

---

## Project structure

```
lib/
  main.dart              App entry, MultiProvider setup
  app.dart               MaterialApp, theme, router
  core/                  Theme, database, router, utils
  models/                Purchase, Sale, Debt, BusinessSettings, etc.
  providers/             Auth, Purchase, Sale, Debt, Report, Settings
  screens/               Splash, auth, dashboard, modules, settings
  widgets/               Reusable UI components
assets/
  icons/                 App icon source PNGs
  images/
android/                 Android project and release signing config
generate_icon.py         Script to regenerate the app icon
```

---

## Install the release APK

1. Build or obtain `app-release.apk` (see below).
2. Copy the APK to the phone (USB, WhatsApp, Telegram, or Google Drive).
3. Enable **Install unknown apps** for the app used to open the file.
4. Tap the APK and confirm install.
5. Open **Vynex**. Default PIN: `1234`.
6. Change your PIN when prompted on first launch.

---

## Build from source

### Requirements
- Flutter SDK (stable, 3.x+)
- Android SDK (compile/target API 36)
- Python 3 + Pillow (optional, for regenerating the app icon)

### Steps

```bash
flutter pub get
python generate_icon.py          # optional, icons already in assets/
dart run flutter_launcher_icons  # optional, mipmaps already generated
flutter run                      # debug on connected device
flutter build apk --release      # release APK
```

Release output: `build/app/outputs/flutter-apk/app-release.apk`

### Release signing

Copy `android/key.properties.example` to `android/key.properties` and create a keystore:

```bash
keytool -genkey -v -keystore android/app/vynex-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias vynex
```

Never commit `key.properties` or `*.jks` files. They are gitignored.

---

## Database schema (V1)

| Table | Purpose |
|-------|---------|
| `purchases` | Stock bought, cost, date, notes |
| `sales` | Sales, profit, payment method, sale type, paid status |
| `debts` | Linked to sales, payments, balance, cleared flag |
| `business_settings` | Profile, currency, PIN hash |

Schema version: **3** (includes payment_method, sale_type, payment_history).

---

## Security and privacy

- No internet permission in the Android manifest
- No Firebase, analytics, or cloud sync
- PIN stored as SHA-256 hash only
- All business data remains on the device
- Backup files are plain SQLite exports shared at the user's choice

---

## Retrieving Vynex V1 later

This repo is the V1 baseline. When V2 development advances, you can always return to V1:

```bash
git checkout v1.0.0
# or clone and checkout the tag
git clone https://github.com/victor964/Vynex_mobile.git
cd Vynex_mobile
git checkout v1.0.0
```

---

## V2 roadmap (planned)

V2 will build on this codebase. Possible directions include inventory levels, multi-user support, receipt printing, and enhanced reporting. V1 remains frozen at tag `v1.0.0` for reference and rollback.

---

## License

Copyright (c) Victor / Vynex project owner. All rights reserved.

This is a private commercial project. Unauthorized copying, distribution, or use is prohibited unless explicitly permitted by the owner.

---

## Author

**Victor** | [GitHub](https://github.com/victor964)

Repository: [victor964/Vynex_mobile](https://github.com/victor964/Vynex_mobile)
