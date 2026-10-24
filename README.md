# Kaval (കാവൽ) — AI watch-post network for the Kerala Forest Department

Built solo at the **DevDay Exchange Community Hackathon: Kochi**. Template docs: **[Event rules](RULES.md)** · **[Agent instructions](AGENTS.md)** · **[Submission](SUBMISSION.md)** · **[AI usage](AI_USAGE.md)** · **[Change log](CHANGELOG.md)**

## Project overview

- **Project name:** Kaval (Malayalam for "watch / guard")
- **Short description:** A forest watcher sits in a watch post all night to spot elephants near villages (Kottappady, Kodanad Range) or sandalwood cutters in the dark (Marayoor). Kaval replaces the eyes and ears of that post with a small AI camera node and gives the Range Officer one phone app to watch every post in the range: a map of posts, red pins on alerts, the latest snapshot, battery and a live alert feed. Helps Kerala Forest Department field staff and the fringe villages they protect.
- **Team:** Madhav ([@PASUMBA](https://github.com/PASUMBA)) — solo
- **Working demo:** Android APK built from this repo (`flutter build apk`, see below) + one Seeed reCamera running the Node-RED flow in `node-red/`. Demo mode in the app works with no hardware at all.
- **Technology stack:** Flutter (Dart) Android/web app · Seeed reCamera (RISC-V, stock `yolo11n` model) · Node-RED flow on the camera serving a small HTTP API · OpenStreetMap tiles via `flutter_map`

### What is actually built and working

| Part | Status |
| --- | --- |
| reCamera detection → event classification (elephant/bear = wildlife alert, person at night 18:00–06:00 IST = intrusion, vehicle/cattle/dog/bird = log only, 3-frame hold against false alarms) | Working, tested live |
| Camera HTTP API: `GET /api/watcher` (JSON), `GET /api/snapshot.jpg`, `GET /api/gimbal`, `GET /api/watcher/raw`, `GET /api/net` (camera IP, for hotspot setup) | Working, tested live |
| Audio: 2 s `arecord` sample every 6 s, RMS loudness, 3 loud samples → "chainsaw" event | Working (loudness rule, **not** a trained classifier) |
| Flutter app: Login → Range select → Map with post pins (green ok / red alert / grey offline) → post detail (battery, last detection, snapshot, history) → Alerts tab with sound → Settings (Demo / Live camera, camera URL, connection status) | Working on Android (APK v1.0.6) and web build |
| App polls each live post every 3 s, 8 s timeout, pin goes grey after 25 s of silence; snapshot fetched once per new detection | Working |
| Demo mode: simulated posts in 5 ranges so the "network of posts" can be shown with one real camera | Working |

### Run the project

1. **Prerequisites and versions:** Flutter 3.x with Dart SDK ≥ 3.9.2, Android SDK (for the APK). For the real post: one Seeed reCamera with Node-RED (port 1880) and the stock `yolo11n` model.
2. **Dependency installation:** `flutter pub get`
3. **Environment setup:** no secrets or `.env` needed. Camera-side optional env vars in the Node-RED tab: `KV_NAME`, `KV_BATTERY`, `KV_QUIET_FROM` (default 18), `KV_QUIET_TO` (default 6), `KV_AUDIO_THRESH` (default 12).
4. **Start the project:**
   - App on a phone/emulator: `flutter run`
   - Release APK (what was used in the demo): `flutter build apk --release --target-platform android-arm64` → `build/app/outputs/flutter-apk/app-release.apk`
   - Web build: `flutter build web` then serve `build/web/`
   - Camera: Node-RED menu → Import → paste `node-red/kaval_tab_only.json` → Deploy. In the model node tick **Debug** so frames are included. Check `http://<camera-ip>:1880/api/watcher` returns JSON.
   - Connect app to camera: Settings → **Live camera** → URL `http://<camera-ip>:1880` → Save. Post **KDN-01 (Vadakkumbhagam Post, Kodanad Range)** becomes the real camera; other posts stay simulated.
5. **Run checks or tests:** `flutter analyze` (static analysis). No automated tests yet; checks done are listed in [SUBMISSION.md](SUBMISSION.md).

### Demo walkthrough

1. Open app → log in (any ID/password in this prototype) → choose **Kodanad Range**.
2. Map shows posts; tap **KDN-01**.
3. Stand in front of the camera (or play a loud chainsaw sound for ~6 s) → pin turns red, Alerts tab gets a notification with sound, detail page shows the snapshot and history.
4. Without hardware: keep **Demo mode** and use the "Demo triggers" chips on a post's detail page.

### Current status

- **Working features:** see table above.
- **Known limitations:**
  - "Real-time" is 3 s HTTP polling, no push notifications.
  - Camera link in the demo was a Cloudflare quick tunnel (camera on USB); the intended link is plain Wi-Fi on the phone hotspot.
  - Login has no real authentication; posts other than KDN-01 are simulated.
  - Audio detection is a loudness threshold, not a chainsaw model.
  - Camera LED alert output (GPIO490) is disabled by default — it browned out the USB-powered camera.
  - Not built (future work): servo gimbal tracking (`firmware/esp32-gimbal-bridge/` sketch exists but was never wired or tested), LoRa backhaul between posts and the range office, cloud backend, multiple real cameras.
- **Libraries, APIs, and public datasets used:**
  - Flutter packages: [flutter_map](https://pub.dev/packages/flutter_map), [latlong2](https://pub.dev/packages/latlong2), [http](https://pub.dev/packages/http), [provider](https://pub.dev/packages/provider), [audioplayers](https://pub.dev/packages/audioplayers), [shared_preferences](https://pub.dev/packages/shared_preferences), [intl](https://pub.dev/packages/intl)
  - Map tiles: [OpenStreetMap](https://www.openstreetmap.org/copyright) (© OpenStreetMap contributors)
  - Detection model: stock `yolo11n` (COCO classes) shipped with the Seeed reCamera, run through [Node-RED](https://nodered.org/) on the camera
  - Post locations are approximate public coordinates of Kerala forest ranges, entered by hand

## Repository layout

```
lib/                      Flutter app (main, models, store, screens_auth, screens_home, theme)
assets/alert.wav          alert sound
node-red/                 reCamera Node-RED flows (kaval_tab_only.json = import this; deployed_* = backups of what ran on the camera)
firmware/esp32-gimbal-bridge/   ESP32 servo/relay sketch — written, NOT used in the demo
android/, web/            Flutter platform folders
```

See [AI_USAGE.md](AI_USAGE.md) for AI assistance and [CHANGELOG.md](CHANGELOG.md) for the development record.
