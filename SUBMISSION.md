# Project submission

## Project

- **Project name:** Kaval (കാവൽ)
- **Short description:** Forest watchers in Kerala guard watch posts all night against elephants entering villages (Kottappady, Kodanad Range) and sandalwood cutters (Marayoor). Kaval is an AI watch post built on a Seeed reCamera (on-device YOLO + microphone loudness rule, no internet needed) plus a Flutter app for the Range Officer: map of posts, red pin + alert with sound on detection, latest snapshot, battery and history. Benefits Kerala Forest Department field staff and fringe-village residents.
- **Code repository URL:** https://github.com/PASUMBA/Kaval
- **Final submitted implementation commit SHA:** TODO — fill in after the last code commit (`git rev-parse HEAD`)
- **Working demo URL or local demo steps:** Install the APK built from this repo (or run `flutter run`), log in, choose Kodanad Range, tap post KDN-01. With the reCamera connected (Settings → Live camera → camera URL), stand in front of the camera → pin turns red and an alert appears. Without hardware, Demo mode shows simulated posts and "Demo triggers".
- **Demo access requirements:** Android phone (arm64) or Chrome for the web build; optional Seeed reCamera on the same Wi-Fi running `node-red/kaval_tab_only.json`. Internet only needed for OpenStreetMap tiles. No credentials.

## Participants

| Participant name | GitHub handle | Contribution |
| --- | --- | --- |
| Madhav | [@PASUMBA](https://github.com/PASUMBA) | Problem, product design, hardware (reCamera, Node-RED deployment, tunnel/Wi-Fi), testing on phone, direction of the AI coding agent (see [AI_USAGE.md](AI_USAGE.md)) |

## Run and demonstrate

- **Prerequisites and versions:** Flutter 3.x (Dart ≥ 3.9.2), Android SDK; optional Seeed reCamera with Node-RED 1880 and stock `yolo11n`.
- **Install command:** `flutter pub get`
- **Required environment variable names:** none for the app. Camera-side optional: `KV_NAME`, `KV_BATTERY`, `KV_QUIET_FROM`, `KV_QUIET_TO`, `KV_AUDIO_THRESH`.
- **Start command:** `flutter run` (or `flutter build apk --release --target-platform android-arm64`, or `flutter build web`)
- **Demo walkthrough:** Login → Kodanad Range → Map → KDN-01 → person in front of camera (or loud steady noise ~6 s) → red pin, Alerts tab notification with sound, snapshot + history in detail page. Settings shows "Connected · last reply Xs ago".
- **Checks performed and results:** `flutter analyze` on the app; manual walkthrough of every screen in the web build and on an Android phone (APK v1.0.5); live test of camera → `/api/watcher` → app with real person detections, snapshot and audio level; reply time measured 0.5–1.9 s after the lighter flow. No automated tests.
- **Known limitations or incomplete features:** 2 s polling, no push; demo link was a Cloudflare tunnel (camera on USB) instead of hotspot Wi-Fi; login not real; only KDN-01 is a real camera, other posts simulated; audio is a loudness rule, not a trained model; camera LED output disabled (USB brown-out); gimbal sketch, LoRa backhaul and cloud backend are future work and were not built.
- **Libraries, APIs, and public datasets used:** flutter_map, latlong2, http, provider, audioplayers, shared_preferences, intl (pub.dev); OpenStreetMap tiles (© OpenStreetMap contributors); Node-RED; Seeed reCamera stock `yolo11n` (COCO) model. No external datasets.
- **AI usage record:** [AI_USAGE.md](AI_USAGE.md)
- **Development change log:** [CHANGELOG.md](CHANGELOG.md)

## Submission checklist

- [x] The project implementation started from scratch at the event (reused only the idea of HTTP polling from an earlier personal project; all code written tonight).
- [x] I participated solo.
- [x] An AI coding agent (Devin) was used during development and its usage is documented.
- [x] The code repository URL, short description, and working demo are provided.
- [x] README setup and demo instructions match the submitted code.
- [x] Actual checks and known limitations are documented.
- [x] Meaningful changes are documented and committed throughout development.
- [ ] The final implementation is committed and pushed, and its SHA is recorded above.
- [x] No credentials or private data are included in the repository or demo instructions.
- [ ] The organizers' announced submission method and timing have been followed.

Event reference: [DevDay Exchange Community: Kochi on Luma](https://luma.com/z10nz8gp).
