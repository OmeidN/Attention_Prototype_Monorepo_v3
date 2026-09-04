# M02 — App Selection

**Goal:** the tester can pick individual launchable apps, see **real names and icons**, multi-select, and persist `{ id: UUID, packageName, dateAdded }` across process death and relaunch.

**User-visible change:** an app-picker list with system labels/icons, selected count, persistence. No naming-your-apps step.

**Prerequisite:** M01 PASS on a physical device.

**Agent rule:** implement this milestone only. Stop after `assembleDebug` succeeds. Do not mark PASS. **Do not add an iOS-style required nickname screen.**

## Settled decision

Android has no token privacy layer. Showing "TikTok" from `applicationInfo.loadLabel(pm)` is correct. Copying iOS's mandatory naming step would be a worse onboarding for no API reason.

## Out of scope

- Usage Access, UsageEvents → **M03**
- Treating selection as OS-level blocking — this only stores records
- `QUERY_ALL_PACKAGES` unless the launcher-intent query is proven insufficient (record that)
- Interventions → **M06**
- Required nicknames. Optional nickname field is **not** in this milestone.

## Context

Attention needs individual-app targeting. Android 11+ hides packages unless the app declares visibility. Use the **minimal** launcher-intent `<queries>` declaration.

## Steps for the agent

1. In `AndroidManifest.xml` add only:

   ```xml
   <queries>
     <intent>
       <action android:name="android.intent.action.MAIN" />
       <category android:name="android.intent.category.LAUNCHER" />
     </intent>
   </queries>
   ```

   Do not add `QUERY_ALL_PACKAGES` in this milestone.

2. `AppCatalog`: `queryIntentActivities` for `ACTION_MAIN` + `CATEGORY_LAUNCHER`. Map to `loadLabel`, `loadIcon`, `packageName`. Exclude this prototype. Sort by label.
3. Experiments: scrollable list with **real** icon, **real** label, package name, checkbox. Multi-select. `Selected: N`. Search/filter optional.
4. Persist a list of `{ id: UUID, packageName: String, dateAdded: ISO-8601 }` (JSON in ExperimentStore is enough — no Room). Identity key for lookups is `packageName`. Restore checks on launch. Log `selection_changed` with count + package names, tag `ATTN-M02`.
5. If the query returns nothing, show that — do not fake apps.
6. Do not read UsageStats. Optional one-row "open to verify package" debug action is allowed.

## Agent exit checks

```text
.\gradlew.bat assembleDebug
```

- [ ] Debug APK builds
- [ ] Manifest has launcher `<queries>` and does **not** have `QUERY_ALL_PACKAGES`
- [ ] Records include UUID + packageName + dateAdded; UI uses system labels/icons
- [ ] Grep for a required naming/nickname screen → zero
- [ ] Grep `src/` for `UsageStatsManager`, `AccessibilityService` → zero hits

## Physical-device checklist (human)

- [ ] List shows real installed apps with correct names/icons (not a stub)
- [ ] Select Instagram/YouTube/etc., force-stop, reopen — selection still there **with names/icons**
- [ ] Reboot, reopen — still there
- [ ] Deselect all, relaunch — empty
- [ ] Confirm you were **not** asked to type app names
- [ ] Note missing major apps (package visibility gap)
- [ ] Record PASS/FAIL in `docs/TEST_RESULTS.md`

## Definition of done

- [ ] Launchable apps with real labels/icons, UUID+packageName persistence
- [ ] No iOS naming port
- [ ] Human recorded physical-device evidence

**Next:** [M03 — Usage Access and Raw Events](./MILESTONE_03_USAGE_ACCESS_AND_EVENTS.md)
