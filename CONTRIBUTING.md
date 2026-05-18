# Contributing to Flowlytics

> **Medical disclaimer:** Flowlytics works entirely on mathematical modelling of personal cycle history. It is not a clinical tool. Its predictions are estimates and do not represent real biology. If you are contributing to the prediction logic, hormone engine, Navigator, or any feature that surfaces health-related information to the user, keep this in mind at all times. Do not introduce changes that make the app appear more medically authoritative than it is. The app must never be presented or modified in a way that implies it can be used for contraception or as a substitute for medical advice.

Thanks for taking the time to contribute. Flowlytics is a health tool that real people use to track sensitive data, so contributions are held to a thoughtful standard. Read this before opening a pull request.

---

## What kinds of contributions are welcome

- Bug fixes with a clear description of what was wrong and how the fix addresses it
- Improvements to the prediction or hormone engine accuracy (see notes below)
- UI and accessibility improvements
- Localization (new language support)
- Documentation fixes and wiki improvements
- New test coverage

If you want to work on something larger, open an issue first. This avoids the situation where you put significant effort into something that does not align with the project direction.

---

## What to avoid

- Changes that add network requests, analytics, or any form of telemetry. The offline-first principle is non-negotiable.
- Changes that weaken existing security for users who have already set up the app.
- Features that require an account or any server-side component.
- Dependency additions that are not clearly justified.

---

## Getting started

**1. Fork the repository**

**2. Clone your fork**
```bash
git clone git@github.com:YOUR_USERNAME/flowlytics.git
cd flowlytics
```

**3. Set up the security config**
```bash
cp keys/security_config.dart.example keys/security_config.dart
```
Edit the file and set your own `backupSecretKey` (32 chars) and `backupIv` (16 chars). These are used for local AES encryption and are gitignored. Never commit this file.

**4. Install dependencies**
```bash
flutter pub get
```

**5. Generate Hive adapters**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**6. Run the app**
```bash
flutter run
```

---

## Before submitting a pull request

- Keep commits focused. One logical change per commit.
- Use conventional commit messages:

```
feat(engine): add LH curve to hormone model
fix(navigator): prevent mid-cycle false positive on mood nudge
docs(wiki): update prediction engine confidence table
refactor(backup): simplify import validation logic
```

---

## Engine contributions

The prediction and hormone engines touch the core of what this app does. If you are proposing changes to curve parameters, weighting schemes, or symptom thresholds, please:

- Explain the biological or statistical basis for the change
- If possible, include data or a reference that supports the change
- Open an issue to discuss before writing code

Women developers and health researchers are especially encouraged to contribute here. Domain knowledge matters more than clever code in this area.

---

## Security contributions

Security changes require an issue discussion before any code is written. Any change that reduces the protection level for existing users will be rejected, regardless of other merits.

See the [Security Architecture](https://github.com/harshit2k4/flowlytics/wiki/Security-Architecture) wiki page for how the current system works.

---

## Reporting bugs

Open an issue on GitHub. Include:
- What you expected to happen
- What actually happened
- Steps to reproduce
- Device and OS version
- Flutter version (`flutter --version`)

Do not include any personal health data in bug reports.

---

## License

By contributing, you agree that your changes will be licensed under the same [AGPL-3.0 license](./LICENSE) as the rest of the project. This means any derivative work must also be open source.