# ResQMesh — Offline Emergency Communication

ResQMesh is an Android-first Flutter application demonstrating offline-first emergency communication between nearby phones. It combines peer discovery, explicit connection approval, peer-to-peer byte messaging, SOS messages with GPS coordinates, and a local SQLite message history.

## Implemented in this source package

- Flutter application with a responsive Material 3 interface.
- Nearby device discovery and advertising through Google's Nearby Connections API (`nearby_connections`).
- Explicit accept/reject handling for incoming connection requests.
- Peer connection and disconnection controls.
- JSON message exchange over connected nearby devices.
- Emergency SOS creation, local persistence, and sending to currently connected peers.
- Current GPS coordinate capture when location permission and location services are available.
- SQLite persistence for received messages and SOS records.
- Riverpod dependency scope and a shared nearby-service provider.
- Runtime permission requests and Android manifest declarations.
- Basic widget test.

## Platform and verification status

**Android is the supported target for the current transport implementation.** The `nearby_connections` plugin is Android-only. This package is not an iOS implementation.

The source is provided as a complete implementation baseline, but it has **not been built or tested on physical Android phones in this environment**. Before describing it as production-ready, run the build and two-device test plan below. Nearby Connections requires compatible real devices; an emulator is not a valid end-to-end test.

The app does not contact emergency services, guarantee message delivery, provide multi-hop mesh routing, or perform background delivery when the app is closed. SOS is delivered only to peers connected at the time the user sends it. Location is optional and depends on device settings and permissions. Do not rely on this app as the sole emergency channel.

## Requirements

- Flutter stable with Dart 3.3 or newer.
- Android Studio / Android SDK.
- Android 6.0+ phone recommended; test with two physical Android phones.
- Bluetooth and Location enabled on both phones. Nearby Connections may also use Wi-Fi.

## Setup

1. Install Flutter and Android Studio.
2. Extract this project.
3. Open a terminal in the `ResQMesh` folder.
4. Run:

```bash
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run
```

If the Android platform wrapper is missing from your local Flutter installation, generate it from the project root with:

```bash
flutter create --platforms=android --org com.resqmesh .
```

Then re-run `flutter pub get`.

## Two-phone test plan

1. Install and open the app on both physical Android phones.
2. Grant nearby-device, Bluetooth and location permissions; turn Bluetooth and Location on.
3. On Phone A, open **Nearby mesh** and tap **Become visible**.
4. On Phone B, open **Nearby mesh** and tap **Find devices**.
5. Tap **Connect** on the discovered device. Accept the incoming connection on the other phone.
6. Send a test message. Confirm it appears in the other phone's message history.
7. Trigger an SOS on one phone. Confirm the connected peer receives the SOS and coordinates when GPS is available.
8. Force-close and reopen the app; confirm local message history persists.

Repeat with devices from different manufacturers and Android versions. Record results and screenshots before publishing a release.

## GitHub

Create a new repository named `ResQMesh`, then from this folder run:

```bash
git init
git add .
git commit -m "Build ResQMesh offline emergency communication app"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/ResQMesh.git
git push -u origin main
```

Replace `YOUR-USERNAME` with your GitHub username. Do not commit signing keys, private credentials, or personal location data.

## Architecture

```text
lib/
  core/
    data/       SQLite local persistence
    models/     Message model
    services/   Nearby Connections and GPS
  features/
    home/       Dashboard
    mesh/       Discovery, connection, messaging
    sos/        Emergency alert flow
    messages/   Local history
```

## Security and privacy notes

- Incoming connections require user acceptance.
- Nearby Connections handles the underlying transport; do not assume that this app adds end-to-end identity verification.
- Messages and coordinates are stored locally in the app database.
- Avoid sending sensitive personal information during testing.
- A future hardened release should add peer identity verification, signed message envelopes, replay protection, expiry/TTL, rate limiting, encrypted local database storage, and a delivery acknowledgement protocol.
