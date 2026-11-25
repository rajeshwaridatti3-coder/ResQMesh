# ResQMesh verification checklist

## Automated checks
- [ ] `flutter pub get` completes.
- [ ] `flutter analyze` completes without errors.
- [ ] `flutter test` passes.

## Physical-device checks (two Android phones)
- [ ] Runtime permissions can be granted.
- [ ] Advertising starts on Phone A.
- [ ] Discovery finds Phone A from Phone B.
- [ ] Incoming connection request is shown and can be rejected.
- [ ] Accepted connection appears in connected-device list.
- [ ] Text message is received and persisted on the second phone.
- [ ] SOS is persisted on sender and delivered to connected peer.
- [ ] GPS coordinates are included when location is available.
- [ ] Message history remains after app restart.
- [ ] Disconnect and stop controls work.

Record phone models, Android versions, test date, and results before claiming these checks passed.
