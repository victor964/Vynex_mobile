# Vynex | Offline Business Manager

<p align="center">
  <img src="assets/icons/app_icon.png"
       alt="Vynex Logo" width="120"/>
</p>

<p align="center">
  <strong>A fully offline Android business management
  app for small-scale traders.</strong><br/>
  No internet required. No monthly fees.
  All data stays on your phone.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.0.0-FFD700?style=flat-square&labelColor=1a1a1a"/>
  <img src="https://img.shields.io/badge/Platform-Android-FFD700?style=flat-square&labelColor=1a1a1a"/>
  <img src="https://img.shields.io/badge/Flutter-3.x-FFD700?style=flat-square&labelColor=1a1a1a"/>
  <img src="https://img.shields.io/badge/Min%20Android-5.0%20(API%2021)-FFD700?style=flat-square&labelColor=1a1a1a"/>
  <img src="https://img.shields.io/badge/License-MIT-FFD700?style=flat-square&labelColor=1a1a1a"/>
</p>

---

## What is Vynex?

Vynex is a mobile Point of Sale and business management
app built for small-scale traders who manage their
business using a counter book. It replaces manual record
keeping with a fast, clean and reliable digital system
that works entirely offline.

---

## What is New in V2

| Feature | Description |
|---|---|
| Product Catalog | Central library of all your products |
| Inventory Tracking | Stock levels with low stock alerts |
| Barcode Scanning | Scan via camera or type manually |
| Sale Source Tracking | From Stock, Spot Buy, Service |
| Customer Database | Profiles with full purchase history |
| Invoice PDF | Professional invoices shareable via WhatsApp |
| Enhanced Reports | Inventory and customer analytics tabs |

---

## Full Feature List

### V1 Features (retained in V2)
- PIN-secured login with custom 4-digit PIN
- Purchase recording with date backdating
- Sales with auto profit calculation
- Payment method: Cash, M-Pesa, Paybill/Till
- Service sales (revenue equals profit)
- Debt tracking with installment payment history
- Reports with charts and period filters
- Excel export for sales, purchases and debts
- Business settings with backup and restore
- 100% offline, no internet needed

### V2 New Features
- Product Catalog with categories (predefined + custom)
- Barcode scanning via phone camera (optional shortcut)
- Inventory tracking with stock movement audit trail
- Manual stock adjustment with reason logging
- FROM STOCK sales deduct inventory automatically
- SPOT BUY sales for items sourced on the spot
- RESTOCK purchases increase inventory automatically
- Customer database with name, phone, email, notes
- Full purchase history per customer
- Outstanding debt tracking per customer
- Customer linking on sales (optional)
- Invoice PDF generation with business branding
- Invoice number format: VYX-YEAR-XXXX
- Invoice history per customer and per sale
- Sale source breakdown pie chart in reports
- Inventory report tab: stock value, dead stock,
  top moving items
- Customer report tab: top customers, debt summary
- Excel export for inventory and customer reports

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (latest stable) |
| Language | Dart (null safe) |
| State Management | Provider |
| Local Database | SQLite via sqflite |
| Navigation | GoRouter |
| Charts | fl_chart |
| Barcode Scanner | mobile_scanner |
| Excel Export | excel package |
| PDF Generation | pdf + printing |
| File Sharing | share_plus |
| File Picking | file_picker |
| Date Formatting | intl |
| PIN Hashing | crypto (SHA-256) |
| Session Storage | shared_preferences |

---

## Database Schema (V2, version 4)

V2 adds 5 new tables on top of V1:
  categories, products, stock_movements,
  customers, invoices

V2 adds new columns to V1 tables:
  sales: product_id, sale_source, customer_id, spot_cost
  purchases: product_id, purchase_type
  debts: customer_id

All V1 data is preserved when upgrading from V1 to V2.

---

## Sale Source Types

| Source | Stock Deducts | Catalog Required | Profit |
|---|---|---|---|
| FROM STOCK | Yes | Yes | selling minus catalog cost |
| SPOT BUY | No | No | selling minus spot cost |
| SERVICE | No | No | full service fee |
| MANUAL | No | No | selling minus cost (V1 style) |

---

## Building from Source

```bash
# Clone the repository
git clone https://github.com/victor964/Vynex_mobile.git
cd Vynex_mobile

# Install dependencies
flutter pub get

# Generate app icons
python generate_icon.py
dart run flutter_launcher_icons

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

---

## Version History

| Version | Tag | Description |
|---|---|---|
| 1.0.0 | v1.0.0 | First release. Sales, purchases, debts, reports |
| 2.0.0 | v2.0.0 | V2 release. Catalog, inventory, customers, invoices |

To retrieve V1 code at any time:
```bash
git checkout v1.0.0
```

To return to V2:
```bash
git checkout main
```

---

## Device Compatibility

Works on all Android phones running Android 5.0 (API 21)
or newer. Tested on Samsung SM-A366E (Android 16, API 36).

Compatible with: Samsung, Tecno, Infinix, Itel, Huawei,
Xiaomi, Nokia, Oppo, Realme, Vivo and others.

---

## Distribution

Share the APK file directly via WhatsApp or Telegram.
See INSTALL_GUIDE.md for customer installation steps.

Default PIN on fresh install: 1234
User is prompted to change PIN on first login.

---

## Author

**Victor Maina Njenga**
ICT Professional and Software Developer | Murang'a, Kenya
Portfolio: [vickcode.co.ke](https://vickcode.co.ke)

---

<p align="center">
  Built with Flutter | Made for small business owners
</p>
