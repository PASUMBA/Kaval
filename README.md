# Kaval (കാവൽ) — AI watch-post network for the Kerala Forest Department

Built solo at the **DevDay Exchange Community Hackathon: Kochi**. Template docs: **[Event rules](RULES.md)** · **[Agent instructions](AGENTS.md)** · **[Submission](SUBMISSION.md)** · **[AI usage](AI_USAGE.md)** · **[Change log](CHANGELOG.md)**

## Project overview

- **Project name:** Kaval (Malayalam for "watch / guard")
- **Short description:** A forest watcher sits in a watch post all night to spot elephants near villages (Kottappady, Kodanad Range) or sandalwood cutters in the dark (Marayoor). Kaval replaces the eyes and ears of that post with a small AI camera node and gives the Range Officer one phone app to watch every post in the range: a map of posts, red pins on alerts, the latest snapshot, battery, a live alert feed and an Excel export of detections. A second **Resident mode** gives forest-edge villagers an elephant alert for their own post, a bee-sound deterrent and a one-tap sighting report that officers see.
- **Team:** Madhav ([@PASUMBA](https://github.com/PASUMBA)) — solo
- **Working demo:** Android APK built from this repo (`flutter build apk`, see below) + one Seeed reCamera running the Node-RED flow in `node-red/`, pushing to a Firebase Realtime Database relay. Demo mode in the app works with no hardware at all.
- **Technology stack:** Flutter (Dart) Android/web app · Seeed reCamera (RISC-V, stock `yolo11n` model) · Node-RED flow on the camera (HTTP API + cloud push) · Firebase Realtime Database over plain REST (relay, users, reports, event log) · OpenTopoMap tiles via `flutter_map`

### What is actually built and working

| Part | Status |
| --- | --- |
| reCamera detection → event classification (elephant/bear = wildlife alert, person at night 18:00–06:00 IST = intrusion, vehicle/cattle/dog/bird = log only; min confidence 0.45, vehicle 0.7; 3-frame hold against false alarms) | Working, tested live |
| Camera HTTP API: `GET /api/watcher` (JSON), `GET /api/snapshot.jpg`, `GET /api/gimbal`, `GET /api/watcher/raw`, `GET /api/net` (camera IP, for hotspot setup), `GET /api/relay` | Working, tested live |
| Cloud relay: every 3 s the camera `PUT`s its state to Firebase RTDB `posts/<id>`, the snapshot to `snaps/<id>` when it changes, a per-detection photo to `snaphist/<id>/…`, and appends detections to `events/<id>` | Working, tested live |
| Audio: 2 s `arecord` sample every 6 s, RMS loudness, 3 loud samples → "chainsaw" event | Working (loudness rule, **not** a trained classifier) |
| Officer app: login (officer ID + password checked against `users/` in the database) → Range select → full-screen map with status card (posts / alerts / offline) and pins (green ok / red alert / grey offline, "Connecting…" until first reply) → tap pin = quick-peek card → detail page (battery, last detection, snapshot, history with per-detection photo thumbnails) → Posts tab → Alerts tab with sound + resident reports → drawer (Excel export, Settings, Change range, Sign out) | Working on Android (APK v1.0.9) and web build |
| Resident mode: sign-up with name / phone / password / nearest post → one big status for that post → elephant/bear alert banner → bee-sound deterrent (starts automatically on elephant/bear, manual button) → "Report a sighting" sent to the officers | Working |
| Excel export (`.xlsx`): Posts, Reports and one sheet per post with its detection log from `events/<id>`; Today / 7 d / 30 d / custom / all | Working (download on web, share sheet on Android) |
| App polls each live post every 3 s (camera URL or relay URL), 8 s timeout; relay post marked offline if the camera stopped pushing for 40 s; snapshot fetched once per new detection | Working |
| Demo mode: 20 simulated posts across 5 ranges so the "network of posts" can be shown with one real camera | Working |

### Run the project

1. **Prerequisites and versions:** Flutter 3.x with Dart SDK ≥ 3.9.2, Android SDK (for the APK). For the real post: one Seeed reCamera with Node-RED (port 1880) and the stock `yolo11n` model. Internet on both camera and phone for the relay mode.
2. **Dependency installation:** `flutter pub get`
3. **Environment setup:** no secrets or `.env` needed; the Firebase RTDB URL is in `lib/backend.dart` (`kRelayDb`) and in the flow (`KV_RELAY`). Camera-side optional env vars in the Node-RED tab: `KV_ID` (default `KDN-01`), `KV_NAME`, `KV_BATTERY`, `KV_RELAY`, `KV_QUIET_FROM` (default 18), `KV_QUIET_TO` (default 6), `KV_AUDIO_THRESH` (default 12).
4. **Start the project:**
   - App on a phone/emulator: `flutter run`
   - Release APK (what was used in the demo): `flutter build apk --release --target-platform android-arm64` → `build/app/outputs/flutter-apk/app-release.apk`
   - Web build: `flutter build web` then serve `build/web/`
   - Camera: Node-RED menu → Import → paste `node-red/kaval_watcher_flow.json` (or `kaval_tab_only.json` into an existing reCamera flow) → Deploy. In the model node tick **Debug** so frames are included. Check `http://<camera-ip>:1880/api/watcher` returns JSON and `/api/relay` shows the last push.
   - Connect app to camera: Settings → **Live camera** → Watcher URL = the Firebase RTDB URL (cloud relay, works from anywhere) **or** `http://<camera-ip>:1880` (same Wi-Fi / hotspot) → Save. Post **KDN-01 (Vadakkumbhagam Post, Kodanad Range)** becomes the real camera; other posts stay simulated.
   - Accounts: officer accounts are records under `users/<id>` in the database (`role: officer`, `name`, `hash` = sha256 of `kaval:<password>`); there is no officer sign-up in the app. Residents sign up from the login screen.
5. **Run checks or tests:** `flutter analyze` (static analysis). No automated tests yet; checks done are listed in [SUBMISSION.md](SUBMISSION.md).

### Demo walkthrough

1. **Officer:** open app → Officer → ID + password → choose **Kodanad Range** → map; tap **KDN-01** → quick-peek → More details.
2. Stand in front of the camera (or play a loud steady noise for ~6 s) → pin turns red, Alerts tab gets a notification with sound, detail page shows the snapshot and the photo history.
3. Drawer → **Export Excel** → Today → `.xlsx` with the detection log.
4. **Resident:** sign out → Resident → name, phone, password, post KDN-01 → status card for that post; on an elephant/bear detection the alert banner shows and the bee sound starts; tap **Report a sighting** → appears in the officer's Alerts tab.
5. Without hardware: keep **Demo mode** and use the "Demo triggers" chips on a post's detail page.

### Current status

- **Working features:** see table above.
- **Known limitations:**
  - Firebase RTDB is used over plain REST with no security rules and no Firebase Auth: anyone with the database URL can read or write users, reports and events. Passwords are stored as salted SHA-256 hashes, but this is **not** production-grade authentication.
  - "Real-time" is 3 s HTTP polling, no push notifications.
  - Camera link in the demo was USB + Cloudflare quick tunnel for setup and the Firebase relay for the app; the intended field link is a phone hotspot (`/api/net` helps find the camera IP).
  - Only KDN-01 is a real camera; the other 20 posts are simulated.
  - Detection model is the stock `yolo11n` (COCO classes), not trained on Kerala wildlife; audio detection is a loudness threshold, not a chainsaw model.
  - Camera LED alert output (GPIO490) is disabled by default — it browned out the USB-powered camera.
  - Not built (future work): servo gimbal tracking (`firmware/esp32-gimbal-bridge/` sketch exists but was never wired or tested), LoRa backhaul between posts, physical deterrent at the post, multiple real cameras.
- **Libraries, APIs, and public datasets used:**
  - Flutter packages: [flutter_map](https://pub.dev/packages/flutter_map), [latlong2](https://pub.dev/packages/latlong2), [http](https://pub.dev/packages/http), [provider](https://pub.dev/packages/provider), [audioplayers](https://pub.dev/packages/audioplayers), [shared_preferences](https://pub.dev/packages/shared_preferences), [intl](https://pub.dev/packages/intl), [excel](https://pub.dev/packages/excel), [share_plus](https://pub.dev/packages/share_plus), [path_provider](https://pub.dev/packages/path_provider), [crypto](https://pub.dev/packages/crypto), [web](https://pub.dev/packages/web)
  - Map tiles: [OpenTopoMap](https://opentopomap.org/about) (© OpenStreetMap contributors, SRTM; style CC-BY-SA)
  - Backend: [Firebase Realtime Database](https://firebase.google.com/docs/database) REST API (free tier)
  - Detection model: stock `yolo11n` (COCO classes) shipped with the Seeed reCamera, run through [Node-RED](https://nodered.org/) on the camera
  - Post locations are approximate public coordinates of Kerala forest ranges, entered by hand

## Repository layout

```
lib/                      Flutter app (main, models, store, backend, export, screens_auth, screens_home, screens_resident, theme)
assets/alert.wav, bee.wav alert sound, bee deterrent sound
node-red/                 reCamera Node-RED flows (kaval_watcher_flow.json = import this; deployed_* = backups of what ran on the camera)
tools/                    small Python scripts that patch the relay push / snapshot history nodes into a flow JSON
firmware/esp32-gimbal-bridge/   ESP32 servo/relay sketch — written, NOT used in the demo
android/, web/            Flutter platform folders
```

See [AI_USAGE.md](AI_USAGE.md) for AI assistance and [CHANGELOG.md](CHANGELOG.md) for the development record.
