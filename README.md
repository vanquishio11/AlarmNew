# AlarmLock (Flutter)

An alarm app with:
- Add/Edit/Delete alarms
- Wheel-style time picker (iOS-style)
- Choose a sound (built-in assets or pick a file on device)
- When the alarm rings, it can only be stopped by entering the alarm password

## Important iOS note (platform limitation)
iOS does **not** allow third‑party apps to permanently take over the lock screen or force a custom "password to stop" UI in the background.
This app schedules a local notification and, when you tap the notification, opens a full-screen ringing page that plays the alarm sound until the correct password is entered.

## Run locally
```bash
flutter pub get
flutter run
```

## Codemagic
This repo includes a `codemagic.yaml` workflow. In Codemagic:
- Set up iOS code signing (App Store Connect API Key + certificates/profiles) in the UI.
- Ensure you have a `CM_KEYSTORE` etc. only if you also build Android signed artifacts.

Then build using the included workflow.

