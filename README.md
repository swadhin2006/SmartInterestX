# SmartInterestX 💰
### Loan & Interest Management Mobile App

A fintech-style Flutter mobile application built for **Unlox Academy Major Project**.

---

## Features

| Module | Description |
|--------|-------------|
| M1 — Splash & Onboarding | Animated splash, 4-slide onboarding |
| M2 — Contacts | Add/Edit/Delete borrowers & lenders, search |
| M3 — Transactions | Loan entry, SI calculation, live interest preview |
| M4 — Payments | Payment recording, UPI/Cash/Bank, receipt proof upload |
| M5 — Notifications | Scheduled reminders 1/3/7 days before due date |
| M6 — Dashboard & Analytics | Pie chart, bar chart, totals, filter by contact/year |
| M7 — Export & Backup | CSV export, Firebase cloud backup & restore |

---

## Tech Stack

- **Flutter** (Dart) — UI & Navigation
- **Provider** — State Management
- **SQLite (sqflite)** — Local Database
- **Firebase Firestore** — Cloud Backup
- **firebase_auth** — Google Sign-In
- **flutter_local_notifications** — Scheduled Reminders
- **fl_chart** — Charts
- **csv + share_plus** — Export

---

## Interest Formula

```
SI = (P × R × T) / 100
P = Principal, R = Rate (%), T = Time (months or years)
```

---

## Database Schema (ER Diagram)

```
Contact (id, name, mobile, email, type, createdAt)
    └── Transaction (id, contactId, amount, type, rate, startDate, dueDate, status)
            └── Payment (id, transactionId, amount, mode, date, proofPath)
```

---

## Setup

### 1. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/smart_interest_x.git
cd smart_interest_x
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Connect Firebase (required for cloud features)
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
> This generates `lib/firebase_options.dart` and `android/app/google-services.json`

### 4. Run the app
```bash
flutter run
```

### 5. Build APK
```bash
flutter build apk --release
```

---

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── models/          # Contact, Transaction, Payment
├── db/              # SQLite DatabaseHelper
├── providers/       # ContactProvider, TransactionProvider
├── services/        # InterestService, NotificationService, ExportService, FirebaseService
├── screens/
│   ├── splash/
│   ├── onboarding/
│   ├── home/
│   ├── contacts/
│   ├── transactions/
│   ├── dashboard/
│   ├── analytics/
│   └── settings/
├── widgets/         # SummaryCard, TransactionListTile
└── utils/           # AppTheme, Formatters
```

---

## Submission Checklist

- ✅ Flutter project compiles without errors
- ✅ All modules M1–M7 implemented
- ✅ SQLite local database
- ✅ Firebase Firestore cloud backup
- ✅ Push notifications (1/3/7 days before due)
- ✅ CSV export
- ✅ Payment proof upload
- ✅ Pie chart + Bar chart analytics
- ✅ Live interest preview (SI = P×R×T/100)

---

*Built for Unlox Academy — Major Project 2025*
