<div align="center">

<h1>Flowlytics</h1>

<p>Period tracking and cycle forecasting, with hormone insights and no data ever leaving your device.</p>

[![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-B00020?style=flat-square)](https://www.gnu.org/licenses/agpl-3.0)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-slategrey?style=flat-square&logo=android)](https://github.com/harshit2k4/flowlytics/releases)
[![Release](https://img.shields.io/github/v/release/harshit2k4/flowlytics?style=flat-square&color=2ea44f)](https://github.com/harshit2k4/flowlytics/releases)
[![Stars](https://img.shields.io/github/stars/harshit2k4/flowlytics?style=flat-square)](https://github.com/harshit2k4/flowlytics/stargazers)

<br/>

[**Download APK**](https://github.com/harshit2k4/flowlytics/releases) · [**Report a Bug**](https://github.com/harshit2k4/flowlytics/issues) · [**Request a Feature**](https://github.com/harshit2k4/flowlytics/issues)

</div>

---

## 📸 Screenshots

<div align="center">
<table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/harshit2k4/flowlytics/master/assets/screenshots/dashboard.png" width="160" alt="Dashboard"/></td>
    <td><img src="https://raw.githubusercontent.com/harshit2k4/flowlytics/master/assets/screenshots/hormone_chart.png" width="160" alt="Hormone Chart"/></td>
    <td><img src="https://raw.githubusercontent.com/harshit2k4/flowlytics/master/assets/screenshots/calendar_view.png" width="160" alt="Calendar"/></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/harshit2k4/flowlytics/master/assets/screenshots/insights.png" width="160" alt="Insights"/></td>
    <td><img src="https://raw.githubusercontent.com/harshit2k4/flowlytics/master/assets/screenshots/security_pin.png" width="160" alt="Security PIN"/></td>
    <td><img src="https://raw.githubusercontent.com/harshit2k4/flowlytics/master/assets/screenshots/security_biometrics.png" width="160" alt="Biometric Access"/></td>
  </tr>
</table>
</div>

---

## Table of Contents

- [About the Project](#about)
- [Why Flowlytics?](#why)
- [Features](#features)
- [Technical Architecture](#architecture)
- [Project Structure](#structure)
- [Tech Stack](#stack)
- [Getting Started](#getting-started)
- [Privacy Promise](#privacy)
- [Disclaimer](#disclaimer)
- [Contributing](#contributing)
- [License](#license)

---

<a id="about"></a>

## 🧬 About the Project

Flowlytics is not just a period tracker. It tracks your cycle, models your hormones, and keeps all your data on-device with no server, no account, and no cloud sync required.

> *Built for those who care about accuracy, clean design, and owning their own health data.*

---

<a id="why"></a>

## ⚡ Why Flowlytics?

| | Typical Trackers | Flowlytics |
|---|---|---|
| **Prediction Model** | Fixed 28-day average | Adaptive weighted mean with confidence scoring |
| **Hormone Insight** | None | Full Estrogen, Progesterone & Testosterone wave simulation |
| **Data Storage** | Cloud (server-side) | Local-first, on-device storage |
| **Security** | Password-optional | AES-256 backups + SHA-256 salted PIN + Biometric lock |
| **Symptom Intelligence** | Passive logging | Active cycle refinement via `NavigatorEngine` |
| **Export Format** | CSV or plain PDF | Encrypted `.flytx` backup + Clinical PDF wellness report |

---

<a id="features"></a>

## ✨ Features

<table>
<tr>
<td width="50%">

**📈 Dynamic Hormone Forecasting**
Non-linear modeling of Estrogen, Progesterone, and Testosterone, visualized as fluid waveforms throughout the cycle.

**🧠 Adaptive Prediction Engine**
A statistical engine that learns from cycle history using a weighted mean, with a live Confidence Score shown in the UI.

**🔄 Symptom-Driven Refinement**
The `NavigatorEngine` watches daily logs and adjusts the forecast in real time. Logged flow data overrides the prediction immediately.

**🛡️ System Shield Security**
Global app lock, salted PIN hashing, biometric authentication, and AES-256 encrypted backups enforced at the controller level.

</td>
<td width="50%">

**🧬 Biological Phase Mapping**
Real-time tracking across Menstrual, Follicular, Ovulatory, and Luteal phases with phase-specific wellness guidance.

**📊 Glassmorphic Analytics Suite**
"System Shield" health dashboard with historical trends, delivered through a frosted-glass UI.

**📅 Intelligent Calendar View**
High-performance calendar for daily symptom logging, prediction window visualization, and retroactive cycle review.

**📄 Clinical PDF Reports**
Exportable wellness reports formatted for personal records or clinical consultation.

</td>
</tr>
</table>

---

<a id="architecture"></a>

## 🛠️ Technical Architecture

Flowlytics is built around a set of focused, single-responsibility engines covering prediction, hormone modeling, security, backups, notifications, and reporting, with no overlap between them.

| Engine / Service | What it does | Deep Dive |
|---|---|---|
| `PeriodController` | The main orchestrator. Coordinates data flow between all engines, manages all observables the UI reads from, and handles cycle phase detection, notification scheduling, and data lifecycle. | [Wiki: Period Controller](../../wiki/Period-Controller) |
| `HormoneEngine` | Models Estrogen, Progesterone, and Testosterone levels across the cycle using Gaussian curves. No lookup tables; the math scales to any cycle length. | [Wiki: Hormone Engine](../../wiki/Hormone-Engine) |
| `PredictionEngine` | Forecasts the next period using a recency-weighted mean across up to 6 cycles. Outputs a predicted date, a confidence score, and a window range. | [Wiki: Prediction Engine](../../wiki/Prediction-Engine) |
| `NavigatorEngine` | Sits on top of the prediction and adjusts the date based on today's logged symptoms, from a 1-day nudge on mood signals up to a full override on confirmed flow. | [Wiki: Navigator Engine](../../wiki/Navigator-Engine) |
| `SecurityController` + `SecurityGuard` | Manages PIN hashing, biometric auth, and a progressive lockout on failed attempts. `SecurityGuard` intercepts the widget tree so the lock screen overlays the entire app reactively. | [Wiki: Security Architecture](../../wiki/Security-Architecture) |
| `BackupService` | Serialises all Hive data to JSON, encrypts it with AES-256-CBC, and exports it as a `.flytx` file. Import validates, decrypts, and restores cleanly. | [Wiki: Backup Service](../../wiki/Backup-Service) |
| `NotificationService` | Schedules exact-time, timezone-aware reminders. Notification taps route to specific screens and are lock-screen aware; overlays wait until the app is unlocked before appearing. | [Wiki: Notification Service](../../wiki/Notification-Service) |
| `PdfService` | Generates an offline A4 wellness report using bundled Crimson Text fonts. Covers cycle history and daily symptom logs. Output goes through the native print dialog. | [Wiki: PDF Service](../../wiki/PDF-Service) |

---

<a id="structure"></a>

## 📂 Project Structure

```
flowlytics/
├── core/                    # Global themes, constants, app-wide configurations
├── data/                    # Hive models and TypeAdapters (DailyLog, PeriodLog)
├── keys/                    # Security config (gitignored - see Getting Started)
├── logic/
│   ├── controllers/         # Business logic (SecurityController, PeriodController, ThemeController)
│   └── services/            # Specialized engines (HormoneEngine, PredictionEngine, BackupService)
└── ui/
    ├── charts/              # Hormone waveform visualizations
    ├── home/                # Primary dashboard and daily entry widgets
    ├── insights/            # System Shield analytics and biological reports
    └── widgets/             # Shared UI (Glassmorphism overlays, snackbars)
```

---

<a id="stack"></a>

## ⚙️ Tech Stack

### 🧱 Core Framework & Architecture

| Tool | Version | Role |
|---|---|---|
| [Flutter](https://flutter.dev) | `^3.22.0` | Cross-platform UI framework targeting Android & iOS from a single codebase |
| [Dart](https://dart.dev) | `^3.0.0` | Primary language powering all business logic, mathematical engines, and data models |
| [GetX](https://pub.dev/packages/get) | `^4.7.3` | Lightweight state management, reactive dependency injection, and named routing |

> GetX was chosen over Bloc/Riverpod for its minimal boilerplate. Controllers like `PeriodController` and `SecurityController` stay clean and readable without sacrificing reactivity.

---

### 🗄️ Data & Local Storage

| Tool | Version | Role |
|---|---|---|
| [Hive](https://pub.dev/packages/hive) | `^2.2.3` | High-performance NoSQL key-value store for all on-device health data |
| [Hive Flutter](https://pub.dev/packages/hive_flutter) | `latest` | Flutter lifecycle integration, opens and closes boxes tied to app state |
| [Hive Generator](https://pub.dev/packages/hive_generator) | `latest` | Code-generates `TypeAdapter`s for `DailyLog` and `PeriodLog` models |
| [Build Runner](https://pub.dev/packages/build_runner) | `latest` | Runs the Hive code generation pipeline (`build_runner build`) |

> Hive was chosen over SQLite or shared_preferences for its pure-Dart, zero-native-dependency design and its ability to store typed model objects directly.

---

### 🔐 Security & Privacy

| Tool | Version | Role |
|---|---|---|
| [Encrypt](https://pub.dev/packages/encrypt) | `^5.0.3` | AES-256-CBC encryption for all `.flytx` backup exports |
| [Crypto](https://pub.dev/packages/crypto) | `^3.0.7` | SHA-256 + salt hashing for PIN and security answer storage. The raw values are never saved |
| [Local Auth](https://pub.dev/packages/local_auth) | `^2.3.0` | Hardware-level biometric authentication (Fingerprint & FaceID) checked against both `canCheckBiometrics` and `isDeviceSupported` before enabling |
| [Permission Handler](https://pub.dev/packages/permission_handler) | `latest` | Requests and checks runtime notification permission before scheduling any alerts |

> `SecurityGuard` wraps the entire widget tree and uses GetX `Obx` to reactively overlay the lock screen the instant `isLocked` flips. The app logic underneath never needs to know it was intercepted.

---

### 📊 Visualisation & UI

| Tool | Version | Role |
|---|---|---|
| [FL Chart](https://pub.dev/packages/fl_chart) | `^1.1.1` | Renders the real-time hormone waveform graphs (Estrogen, Progesterone, Testosterone) |
| [Table Calendar](https://pub.dev/packages/table_calendar) | `^3.2.0` | Interactive calendar for cycle logging, prediction window display, and retroactive review |
| [Lottie](https://pub.dev/packages/lottie) | `^3.1.0` | JSON-based fluid animations on the onboarding flow and home screen |
| [Google Fonts](https://pub.dev/packages/google_fonts) | `latest` | Loads **Lexend** for all UI text. Crimson Text is used separately as a bundled asset for the PDF report only |
| [Intl](https://pub.dev/packages/intl) | `latest` | Date formatting used across the PDF report and calendar display (`DateFormat`) |

**Theme system:** 4 built-in themes, each generating a full Material 3 colour scheme from a seed colour using `DynamicSchemeVariant.tonalSpot`. The user's choice is persisted to Hive via `ThemeController` and applied reactively at the `GetMaterialApp` level. Both light and dark variants are generated for every theme.

| Theme | Seed Colour |
|---|---|
| Classic Flow (default) | `#D81B60` |
| Sky Breeze | `#98BAE7` |
| Solar Glow | `#FFD166` |
| Mint Revival | `#A8E6CF` |

---

### 🔔 System & Platform Integration

| Tool | Version | Role |
|---|---|---|
| [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications) | `latest` | Schedules exact-time notifications via `zonedSchedule` with `exactAllowWhileIdle`, fires even in battery-saver mode |
| [Flutter Timezone](https://pub.dev/packages/flutter_timezone) | `latest` | Fetches the device's local IANA timezone name at startup so scheduled notifications fire at the correct local time |
| [Timezone](https://pub.dev/packages/timezone) | `latest` | Converts `DateTime` objects to `TZDateTime` required by `zonedSchedule` |
| [PDF](https://pub.dev/packages/pdf) | `latest` | Builds the A4 clinical wellness report layout using bundled Crimson Text fonts |
| [Printing](https://pub.dev/packages/printing) | `latest` | Opens the native print/share dialog via `layoutPdf`. The PDF never touches disk unintentionally |
| [Share Plus](https://pub.dev/packages/share_plus) | `latest` | Shares the encrypted `.flytx` backup via the native OS share sheet on mobile |
| [File Picker](https://pub.dev/packages/file_picker) | `latest` | Opens the native file browser for backup import and desktop save-file dialogs |
| [Path Provider](https://pub.dev/packages/path_provider) | `latest` | Resolves the correct temp directory for staging the `.flytx` file before sharing on mobile |

---

<a id="getting-started"></a>

## 🚀 Getting Started

If Flowlytics looks useful to you, consider giving it a ⭐ and forking it before you dive in. It helps the project reach more people.

### Prerequisites

- Flutter SDK **3.22.0** or higher
- Dart SDK **3.0.0** or higher

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/harshit2k4/flowlytics.git
cd flowlytics
```

**2. Initialize the security configuration**

The `keys/` directory is gitignored. Copy the example file to create your local configuration:
```bash
cp keys/security_config.dart.example keys/security_config.dart
```

> [!IMPORTANT]
> You must configure your own security keys inside `security_config.dart`. These keys are used for AES backup encryption and **cannot be changed once data has been encrypted** without losing access to existing backups.

**3. Install dependencies**
```bash
flutter pub get
```

**4. Generate Hive serializers**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**5. Run the application**
```bash
flutter run
```

---

<a id="privacy"></a>

## 🔒 Privacy Promise

Flowlytics was built on a single non-negotiable principle: **your biological data belongs to you**.

| Guarantee | Detail |
|---|---|
| ✅ Zero network requests | No analytics SDKs, no telemetry, no cloud sync, ever |
| ✅ Local-first storage | All data lives in Hive on the device |
| ✅ Encrypted exports | `.flytx` files are AES-256 encrypted before leaving the device |
| ✅ No account required | No email, no sign-up, no profile |
| ✅ Fully open source | Every line of code is auditable under AGPL-3.0 |

---

<a id="disclaimer"></a>

## ⚠️ Medical Disclaimer

Flowlytics is a personal tracking tool built on mathematical modelling. It is **not a medical product** and is not a substitute for professional medical advice, diagnosis, or treatment.

**Please read this before using the app.**

All predictions in Flowlytics (period dates, ovulation estimates, fertile windows, and hormone charts) are generated by statistical algorithms running on your personal log history. They are pattern-based estimates. They are not clinical measurements and they are not guaranteed to be accurate for any individual.

Human biology does not follow fixed rules. Stress, illness, sleep changes, travel, weight changes, medication, and underlying hormonal conditions can all shift your cycle in ways no algorithm can anticipate. The app has no way to know about any of these factors unless you log them.

The hormone waveforms shown in the app are mathematical approximations of general population patterns. They do not represent your actual hormone levels. No consumer app can measure hormones.

**Flowlytics must not be used as a method of contraception.** The fertile window estimates are not reliable enough for this purpose. Using this app to try to prevent pregnancy puts you at serious risk. If contraception is a concern, speak to a doctor or healthcare provider.

If you have questions or concerns about your cycle, reproductive health, or any symptoms you are experiencing, please consult a qualified healthcare professional. Do not delay or avoid seeking medical advice because of anything this app shows you.

By using Flowlytics, you accept that the app provides informational estimates only. The developer is not liable for any decisions, medical or otherwise, made on the basis of the app's output.

---

<a id="contributing"></a>

## 🤝 Contributing

Contributions that improve the hormone engine accuracy, refine the prediction logic, or elevate the UI are especially welcome.

I particularly invite **women developers and health researchers** to contribute your domain knowledge and lived perspective are genuinely invaluable when building tools of this nature.

**Steps:**

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit with conventional format: `git commit -m 'feat(engine): describe your change'`
4. Push to your branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

---

<a id="license"></a>

## 📄 License

Distributed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

This license is intentionally strict: any derivative work or service built on Flowlytics must also be open-sourced under the same terms. This ensures the privacy-first principles of this project cannot be stripped away in closed forks.

See [`LICENSE`](./LICENSE) for full terms.

---

<div align="center">

If Flowlytics has been useful to you, consider giving it a ⭐ - it helps the project grow.

<br/>

**Crafted with ❤️ for those who value their privacy**

<br/>

[![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/harshit2k4/flowlytics)

</div>