# iOS Development Environment

Local Apple silicon Mac → Cursor + Xcode → signed build → physical iPhone over USB.

## Recorded environment

- Mac: Apple silicon (M2)
- macOS: 26.6.2 (build 25G83)
- Xcode: 26.6 (build 17F113)
- iOS SDK: 26.5
- Apple Developer: paid Apple Developer Program membership
- Install method: Xcode → USB → physical iPhone
- iPhone model / iOS version: recorded in `TEST_RESULTS.md` by the human

## Working agreement

The Xcode project is hand-authored in-repo. Cursor edits files on disk; Xcode picks them up. Xcode 16+ synchronized file groups mean new Swift files in a target's folder are compiled automatically — no project-navigator step.

Keep the project **closed in Xcode** while Cursor is working, and open it only to sign, run, and test. Both processes writing `project.pbxproj` at once will clobber each other. Xcode legitimately writes back to `project.pbxproj` and the entitlements files when you set the signing team or add capabilities — keep those changes.

## Diagnostics

Keep diagnostics visible on-device. From M05 onward the shield and monitor extensions run as separate processes whose logs do not appear in the host app's console, so shared App Group state surfaced in the app is the primary evidence channel, not Xcode's console.

## Attribution of failures

There is no remote host in this setup. A failure is either a signing/provisioning problem or an Apple-API problem. Record which in `TEST_RESULTS.md`; do not blame Screen Time for a code-signing error.

## Historical note

This prototype was originally scoped for a Windows PC driving a cloud Mac over remote desktop, where USB install to a personal iPhone was uncertain. That constraint no longer applies and the milestones have been updated accordingly. No milestone should defer device testing as "install method TBD."
