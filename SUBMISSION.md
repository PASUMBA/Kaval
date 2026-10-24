# Project submission

## Project

- **Project name:** Kaval (കാവൽ)
- **Short description:** Forest watchers in Kerala guard watch posts all night against elephants entering villages (Kottappady, Kodanad Range) and sandalwood cutters (Marayoor). Kaval is an AI watch post built on a Seeed reCamera (on-device YOLO + microphone loudness rule, no internet needed) pushing to a Firebase relay, plus a Flutter app: Officer mode (map of posts, red pin + alert with sound, snapshot, photo history, Excel export of detections, resident reports) and Resident mode (elephant alert for the nearest post, bee-sound deterrent, one-tap sighting report). Benefits Kerala Forest Department field staff and fringe-village residents.
- **Code repository URL:** https://github.com/PASUMBA/Kaval
- **Final submitted implementation commit SHA:** TODO — fill in after the last code commit (`git rev-parse HEAD`)
- **Working demo URL or local demo steps:** Install the APK built from this repo (or run `flutter run`), log in, choose Kodanad Range, tap post KDN-01. With the reCamera connected (Settings → Live camera → Firebase relay URL or camera URL), stand in front of the camera → pin turns red and an alert appears. Without hardware, Demo mode shows simulated posts and "Demo triggers".
- **Demo access requirements:** Android phone (arm64) or Chrome for the web build; optional Seeed reCamera running `node-red/kaval_watcher_flow.json`. Internet needed for map tiles, login and the Firebase relay. Officer login needs an account in the database (TODO: Madhav to share a demo officer ID + password with the judges); residents self-register in the app.

## Participants

| Participant name | GitHub handle | Contribution |
| --- | --- | --- |
| Madhav | [@PASUMBA](https://github.com/PASUMBA) | Problem, product design, hardware (reCamera, Node-RED deployment, tunnel/Wi-Fi, Firebase project), testing on phone, direction of the AI coding agent (see [AI_USAGE.md](AI_USAGE.md)) |

## Run and demonstrate

- **Prerequisites and versions:** Flutter 3.x (Dart ≥ 3.9.2), Android SDK; optional Seeed reCamera with Node-RED 1880 and stock `yolo11n`; internet for Firebase.
- **Install command:** `flutter pub get`
- **Required environment variable names:** none for the app. Camera-side optional: `KV_ID`, `KV_NAME`, `KV_BATTERY`, `KV_RELAY`, `KV_QUIET_FROM`, `KV_QUIET_TO`, `KV_AUDIO_THRESH`.
- **Start command:** `flutter run` (or `flutter build apk --release --target-platform android-arm64`, or `flutter build web`)
- **Demo walkthrough:** Officer login → Kodanad Range → Map → KDN-01 → person in front of camera (or loud steady noise ~6 s) → red pin, Alerts tab notification with sound, snapshot + photo history in detail page → drawer → Export Excel. Then Resident sign-up on post KDN-01 → alert banner + bee sound on elephant/bear → Report a sighting with a photo → shows in officer Alerts tab with thumbnail.
- **Checks performed and results:** `flutter analyze` on the app; manual walkthrough of every screen in the web build and on an Android phone (APK v1.0.10); live test of camera → `/api/watcher` → app, and camera → Firebase relay → app, with real person detections, snapshot, photo history and Excel export; resident report round-trip to the officer Alerts tab. No automated tests.
- **Known limitations or incomplete features:** Firebase RTDB used over REST with no security rules / no Firebase Auth (anyone with the URL can read or write); 3 s polling, no push; camera setup link was USB + Cloudflare tunnel instead of hotspot Wi-Fi; only KDN-01 is a real camera, other 20 posts simulated; stock yolo11n, audio is a loudness rule, not a trained model; camera LED output disabled (USB brown-out); gimbal sketch and LoRa backhaul are future work and were not built; Kerala emblem is demo branding only, not an official app.
- **Libraries, APIs, and public datasets used:** flutter_map, latlong2, http, provider, audioplayers, shared_preferences, intl, excel, share_plus, path_provider, crypto, web, image_picker (pub.dev); OpenTopoMap tiles (© OpenStreetMap contributors, SRTM); Firebase Realtime Database REST API; Node-RED; Seeed reCamera stock `yolo11n` (COCO) model. No external datasets.
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
