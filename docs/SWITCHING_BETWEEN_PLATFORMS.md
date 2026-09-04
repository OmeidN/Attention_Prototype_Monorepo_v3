# Switching Between Android and iOS

Switch only at milestone boundaries.

## Android → iOS
1. Commit and push Android work.
2. Update Android `docs/TEST_RESULTS.md`.
3. Mark milestone complete or paused.
4. Pull the same repo on the Mac.
5. Open `prototypes/ios/AttentionAPITest`.
6. Resume the current iOS milestone.

## iOS → Android
Use the same process in reverse.

Avoid copying platform-specific code, sharing unvalidated terminology, or assuming one OS behaves like the other.
