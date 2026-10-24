# Change log

Each meaningful project change during the event, newest first. Timestamps are IST (UTC+05:30).

## Event build log

## 2026-10-24T23:35:00+05:30 — Hackathon template docs added

- Changed: Added `RULES.md`, `AGENTS.md`, `SUBMISSION.md`, `AI_USAGE.md`, this change log, `.github/pull_request_template.md`; rewrote `README.md` from Flutter boilerplate to the project overview; extended `.gitignore` with secret-file rules.
- Why: Match the organizer's `devday-kochi-hackathon-template` structure for submission.
- Validation: Checked local Markdown links and that every claim matches the pushed code (`lib/`, `node-red/`, `firmware/`).
- Limitations: Documentation only, no code change.

## 2026-10-24T23:30:00+05:30 — Disable camera LED alert output by default

- Changed: `node-red/kaval_watcher_flow.json`, `node-red/kaval_tab_only.json`; added `node-red/deployed_2026-10-24_noled.json` backup.
- Why: Driving the four white LEDs on GPIO490 browned out the USB-powered reCamera.
- Validation: Flow redeployed on the camera; `/api/watcher` kept answering.
- Limitations: No physical alert output at the post for now.

## 2026-10-24T23:29:00+05:30 — First push of Kaval code to GitHub

- Changed: Flutter app (`lib/`, `assets/`, `android/`, `web/`, `pubspec.yaml`), Node-RED flows (`node-red/`), ESP32 sketch (`firmware/`), Flutter `.gitignore`.
- Why: Code had only lived on the build machine during the night; needed in the submission repo.
- Validation: `git push` to `main` succeeded; 45 files.
- Limitations: README was still Flutter boilerplate at this commit.

## 2026-10-24T22:52:00+05:30 — App v1.0.5: snapshot refresh limited to once per minute

- Changed: `lib/store.dart`, `pubspec.yaml` (1.0.5+12).
- Why: Snapshot in the detail page was flickering every 2 s; requested a 1-minute refresh.
- Validation: Web build and APK checked against the live camera.
- Limitations: None identified in these checks.

## 2026-10-24T22:37:00+05:30 — Lighter camera flow; app timeout 3 s → 8 s (v1.0.4)

- Changed: Node-RED flow (less model debug data, audio sample every 6 s instead of 3 s) → `node-red/deployed_2026-10-24_light.json`; `lib/store.dart` timeout.
- Why: Camera replies took 6–16 s and the app showed posts as offline.
- Validation: Reply time dropped to 0.5–1.9 s through the tunnel; KDN-01 showed connected.
- Limitations: Still slower over the tunnel than over local Wi-Fi.

## 2026-10-24T22:19:00+05:30 — Settings: Demo / Live camera buttons + connection status (v1.0.3)

- Changed: `lib/screens_home.dart` (SettingsTab), `lib/store.dart`.
- Why: The demo-mode slider snapped back on the phone; buttons plus a "Connected · last reply Xs ago / error" line make the state visible.
- Validation: Toggled on phone and web build; status line updates.
- Limitations: None identified in these checks.

## 2026-10-24T21:56:00+05:30 — Camera live end to end

- Changed: Kaval Node-RED tab deployed on the reCamera (`node-red/deployed_2026-10-24_merged.json`); model node Debug on so frames are served; old Oozham tab disabled.
- Why: Prove reCamera → `/api/watcher` → app with a real detection.
- Validation: `/api/watcher` returned real person detections with correct confidence and IST night-hour intrusion flag; `/api/snapshot.jpg` served the live frame; audio level read.
- Limitations: Link was a Cloudflare quick tunnel over USB, not the planned hotspot Wi-Fi.

## 2026-10-24T21:40:00+05:30 — First working app build (v1.0.0)

- Changed: `lib/` — Login, Range select, Map with pins, Posts list, Watcher detail (battery, gimbal, last detection, history), Alerts tab with sound, Demo mode; `node-red/kaval_tab_only.json`; `firmware/esp32-gimbal-bridge/`.
- Why: Core app flow agreed at ~21:20 IST: login → range → map → post details → notifications.
- Validation: Web build walked through all screens; arm64 release APK installed on the phone.
- Limitations: Demo data only at this point; gimbal sketch written but not wired (dropped later in the night).

## 2026-10-24T21:02:00+05:30 — Project planning

- Changed: No code. Chose the problem (forest watch posts; Kottappady elephant conflict, Marayoor sandalwood cutting), the universal "AI watch post + Range Officer app" framing, and the Wi-Fi-first plan (LoRa after half-time, later dropped).
- Why: Hackathon kick-off.
- Validation: Short news/background check on Kottappady incidents and existing Forest Dept tooling.
- Limitations: None.

## Template setup — 10 October 2026 (organizer)

- Changed: Event README, rules, agent guide, change log, AI usage record, submission checklist, Git ignore rules, and pull request checklist supplied by the organizer's template.
- Why: Consistent starting point for participants.
- Validation: Organizer's own checks.
- Limitations: Documentation scaffolding only.
