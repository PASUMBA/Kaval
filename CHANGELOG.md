# Change log

Each meaningful project change during the event, newest first. Timestamps are IST (UTC+05:30).

## Event build log

## 2026-10-25T05:35:00+05:30 — Node photos added to README

- Changed: `docs/images/node_*.jpg` (3 photos of the built KDN-01 node), new "Hardware node" section in `README.md`.
- Why: Show judges the physical prototype that was built at the event.
- Validation: Images open and render in the README; links checked.
- Limitations: Photos only; no code change.

## 2026-10-25T04:20:00+05:30 — Docs updated for v1.0.10

- Changed: `README.md`, `SUBMISSION.md`, `CHANGELOG.md`, `AI_USAGE.md`.
- Why: Document report photos, emblem branding and web fixes; note the emblem and base64-photo limitations.
- Validation: Checked against `lib/screens_resident.dart`, `lib/models.dart`, `pubspec.yaml` (1.0.10+17), `AndroidManifest.xml`.
- Limitations: Documentation only.

## 2026-10-25T04:07:00+05:30 → 04:16 — v1.0.10: photo on resident reports

- Changed: `lib/screens_resident.dart`, `lib/models.dart` (`SightingReport.photo`), `lib/store.dart`, `lib/pick_web.dart` / `pick_stub.dart`, `lib/screens_home.dart` (thumbnail + enlarge), `pubspec.yaml` (`image_picker`, 1.0.10+17), `AndroidManifest.xml` (CAMERA permission).
- Why: A sighting report is far more useful to the officer with a photo. Camera or gallery, resized to 1024 px, stored base64 with the report. On web `image_picker` did not fire, so a native `<input type=file>` is used instead.
- Validation: Report with photo sent from the web build and shown in the officer Alerts tab.
- Limitations: Photos as base64 in the database; no size cap beyond the 1024 px resize.

## 2026-10-25T03:44:00+05:30 → 03:57 — Branding and web rendering fixes

- Changed: `lib/theme.dart`, `lib/screens_auth.dart`, `lib/screens_home.dart`, `assets/kerala_emblem.png`, `lib/models.dart`.
- Why: Map header rearranged (menu left, status centre, logo right); Government of Kerala emblem as app logo with leaf backdrops on login and drawer. Relay snapshots rendered as data-URI images (CanvasKit showed blank); relay history merged instead of replaced so thumbnails are not lost.
- Validation: Web build and APK checked after each change.
- Limitations: Emblem is demo branding only.

## 2026-10-25T03:50:00+05:30 — Docs updated for v1.0.7–v1.0.9

- Changed: `README.md`, `SUBMISSION.md`, `CHANGELOG.md`, `AI_USAGE.md`.
- Why: Document Resident mode, Firebase relay/backend, officer home redesign and Excel export; record the open-database security limitation.
- Validation: Re-read `lib/backend.dart`, `lib/store.dart`, `lib/screens_resident.dart`, `lib/export.dart`, `pubspec.yaml` (1.0.9+16) and the flow's `kv_push_fn`.
- Limitations: Documentation only.

## 2026-10-25T03:36:00+05:30 — Per-detection photo history; map logo

- Changed: `lib/screens_home.dart`, `lib/models.dart`, `node-red/kaval_watcher_flow.json`, `tools/patch_snaphist.py`.
- Why: History list showed text only; the camera now pushes each detection's frame to `snaphist/<id>/<time>` on the relay and the app shows thumbnails (tap to enlarge). Kaval logo beside the menu button.
- Validation: Thumbnails loaded from the relay on the web build after live detections.
- Limitations: Thumbnails are base64 JSON on the relay, not real image hosting.

## 2026-10-25T03:26:00+05:30 — Web: clear stale service workers

- Changed: `web/index.html`, `web/flutter_service_worker.js`.
- Why: Older web builds left a service worker that served a blank page after updates.
- Validation: Reloaded the hosted web build; page rendered.
- Limitations: One extra reload on first visit after an update.

## 2026-10-25T03:20:00+05:30 — Excel export date range

- Changed: `lib/export.dart`, `lib/screens_home.dart` (`ExportChoice`).
- Why: Officers asked for Today / 7 days / 30 days / custom / everything instead of a single full dump.
- Validation: Exported each option on the web build; sheets open in Excel.
- Limitations: Events come from the relay `events/<id>`, falling back to in-app history for simulated posts.

## 2026-10-25T02:39:00+05:30 → 03:18 — Officer home redesign

- Changed: `lib/screens_home.dart` (`HomeScreen`, `MapTab`, drawer), `lib/store.dart` (more demo posts).
- Why: Simpler officer flow: full-screen OpenTopoMap (tried Esri satellite/topo first), compact status card, floating menu, tap-pin quick-peek card with "More details", bottom tabs Map / Posts / Alerts, drawer with Export Excel / Settings / Change range / Sign out. Live posts start as "Connecting…" instead of green; no spurious offline/online notifications at start. 20 demo posts across all 5 ranges.
- Validation: Walked through every screen on web and Android (APK v1.0.9).
- Limitations: Map tiles need internet.

## 2026-10-25T02:32:00+05:30 — v1.0.9: Firebase backend (users, reports, events, Excel export)

- Changed: `lib/backend.dart` (new), `lib/export.dart` (new), `lib/download_web.dart` / `download_stub.dart`, `lib/screens_auth.dart`, `lib/store.dart`, `pubspec.yaml` (`excel`, `share_plus`, `path_provider`, `crypto`, `web`).
- Why: Real officer login (`users/<id>` with salted SHA-256 hash), resident sign-up by phone, shared resident reports visible in the officer Alerts tab, per-post detection log `events/<id>` written by the camera, Excel export for the Range Officer.
- Validation: Officer login, resident sign-up, report round-trip and export tested on the web build against the live database.
- Limitations: Database has no security rules and no Firebase Auth — anyone with the URL can read/write. Not production security.

## 2026-10-25T02:10:00+05:30 — v1.0.8: cloud relay

- Changed: `node-red/kaval_watcher_flow.json` (`kv_push_fn`, `PUT relay`, `GET /api/relay`), `tools/add_relay_push.py`, `node-red/deployed_2026-10-24_relay.json`, `lib/store.dart`, `lib/models.dart` (`isRelayUrl`).
- Why: Phone and camera are rarely on the same network; the camera now pushes state every 3 s and the snapshot on change to Firebase RTDB, and the app's Watcher URL can be the relay instead of the camera. Relay post is offline if nothing pushed for 40 s.
- Validation: Live detections reached the app over the relay with the phone on mobile data.
- Limitations: Relay URL hard-coded as default (`kRelayDb`, `KV_RELAY`).

## 2026-10-25T01:20:00+05:30 — v1.0.7: Resident mode

- Changed: `lib/screens_resident.dart` (new), `lib/screens_auth.dart` (role picker), `lib/store.dart`, `assets/bee.wav`, `pubspec.yaml` (1.0.7+14).
- Why: Villagers at the forest edge need the alert too: one post, one big status, elephant alert banner, bee-sound deterrent (auto on elephant/bear, manual button) and a one-tap sighting report.
- Validation: Resident flow checked on web and Android with demo triggers and a live detection.
- Limitations: Bee sound plays from the phone speaker only; no field deterrent hardware.

## 2026-10-25T00:20:00+05:30 — Docs updated for v1.0.6 flow/app changes

- Changed: `README.md`, `SUBMISSION.md`, `CHANGELOG.md`, `AI_USAGE.md`.
- Why: Keep the docs matching the three code commits below (3 s polling, `/api/net`, confidence thresholds).
- Validation: Re-read `lib/store.dart` and the Node-RED flow JSON for the new values and endpoint.
- Limitations: Documentation only.

## 2026-10-25T00:14:00+05:30 — Flow: confidence thresholds and history dedupe

- Changed: `node-red/kaval_watcher_flow.json`, `node-red/kaval_tab_only.json`; backup `node-red/deployed_2026-10-24_v5.json`.
- Why: Low-confidence boxes and repeated vehicle guesses were creating noise; min confidence 0.45, vehicle needs 0.7, history keeps one entry per event type in a row.
- Validation: Flow redeployed on the camera; `/api/watcher` history checked.
- Limitations: Thresholds tuned by eye on one camera, not measured.

## 2026-10-25T00:04:00+05:30 — Flow: add `GET /api/net`

- Changed: `node-red/kaval_watcher_flow.json`, `node-red/kaval_tab_only.json`.
- Why: Returns the camera's IP addresses so the camera can be found on the phone hotspot without a serial console.
- Validation: Endpoint answered on the deployed flow.
- Limitations: Hotspot mode itself was not demoed tonight (demo used the USB + tunnel link).

## 2026-10-24T23:41:00+05:30 — App v1.0.6: poll every 3 s, snapshot once per detection

- Changed: `lib/store.dart`, `lib/screens_home.dart`, `pubspec.yaml` (1.0.6+13); flow caches the decoded snapshot, history length 10.
- Why: Reduce load on the USB-powered camera; snapshot now re-fetched only when a new detection arrives instead of on a timer.
- Validation: Web build against the live camera; reply times stayed under the 8 s timeout.
- Limitations: None identified in these checks.

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
