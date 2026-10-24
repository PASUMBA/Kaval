# AI usage record

Short, honest record of AI assistance on this project. The organizer template assumes Codex; this project was built with **Devin (Cognition)** as the coding agent, so that is what is recorded. Human = Madhav (solo).

## Event build log

| Date and time with timezone | Tool / model, if known | Task | Assistance and affected files | Human review / corrections | Validation and result |
| --- | --- | --- | --- | --- | --- |
| 2026-10-24 21:02–21:20 IST | Devin | Project planning | Read the tracks PDF, discussed problem framing (Kottappady elephant conflict, Marayoor sandalwood), proposed the "universal watch post + Range Officer app" system; no files. | Madhav chose the problem, rejected LoRa for now ("just the cam"), set the app flow (login → range → map → details → notifications). | Plan agreed; background facts checked against news reports. |
| 2026-10-24 21:20–21:40 IST | Devin | Flutter app v1 | Generated `lib/main.dart`, `models.dart`, `store.dart`, `screens_auth.dart`, `screens_home.dart`, `theme.dart`, `pubspec.yaml`, `assets/alert.wav`; built arm64 APK. | Reviewed by walking through every screen; Madhav later asked to drop the gimbal UI emphasis. | Web build and APK ran; all screens reachable. |
| 2026-10-24 21:20–21:56 IST | Devin | reCamera Node-RED flow | Wrote `node-red/kaval_tab_only.json` / `kaval_watcher_flow.json` (classify, 3-frame hold, audio loudness rule, `/api/watcher`, `/api/snapshot.jpg`, `/api/gimbal`); deployed via the Node-RED admin API through Madhav's cloudflared tunnel. | Madhav ran the tunnel and confirmed detections on the phone. | `/api/watcher` returned real person detections; snapshot served. |
| 2026-10-24 21:40 IST | Devin | ESP32 gimbal/relay sketch | `firmware/esp32-gimbal-bridge/esp32-gimbal-bridge.ino`. | Madhav decided not to use the gimbal in the demo. | **Not flashed or tested** — kept as future work only. |
| 2026-10-24 22:10–22:52 IST | Devin | Bug fixes + versions 1.0.1–1.0.5 | Settings toggle → Demo/Live buttons with status line; timeout 3 s → 8 s; lighter camera flow; snapshot refresh once per minute; APK versionCode bumps so installs upgrade cleanly. | Each fix came from Madhav testing on the phone/web and reporting ("slider toggling back", "post offline", "updating fast give 1 min"). | Verified on the live camera through the tunnel after each build. |
| 2026-10-24 23:29–23:30 IST | Devin | Push code to GitHub; disable LED output | `git init`/push of 45 files to `PASUMBA/Kaval`; `node-red/*` LED alert off by default, `deployed_2026-10-24_noled.json`. | Madhav approved the push from a second Devin session. | Push succeeded; flow redeployed and answering. |
| 2026-10-24 23:35 IST | Devin | Hackathon template docs | `README.md`, `RULES.md`, `AGENTS.md`, `SUBMISSION.md`, `AI_USAGE.md`, `CHANGELOG.md`, `.github/pull_request_template.md`, `.gitignore`. | Pending Madhav's review before merge. | Markdown links and claims checked against the code. |
| 2026-10-24 23:41 – 2026-10-25 00:14 IST | Devin | App v1.0.6 + flow tuning | `lib/store.dart`, `lib/screens_home.dart`, `pubspec.yaml` (poll 3 s, snapshot per detection); flow: snapshot cache, history 10, `/api/net`, confidence 0.45 / vehicle 0.7, history dedupe. | Madhav tested on the live camera and reported noise/false vehicle hits. | Flow redeployed and `/api/watcher` answering; `/api/net` returned the camera IP. |
| 2026-10-25 00:20 IST | Devin | Docs sync for v1.0.6 | `README.md`, `SUBMISSION.md`, `CHANGELOG.md`, `AI_USAGE.md` updated to the new polling interval, endpoint and version. | Pending Madhav's review in PR #1. | Values re-checked against `lib/store.dart` and the flow JSON. |
| 2026-10-25 01:20 – 03:36 IST | Devin | v1.0.7–v1.0.9: Resident mode, Firebase relay + backend, officer home redesign, Excel export, photo history | New `lib/screens_resident.dart`, `lib/backend.dart`, `lib/export.dart`; relay push nodes in the flow (`tools/add_relay_push.py`, `tools/patch_snaphist.py`); map/drawer/quick-peek redesign; web service-worker fix. | Madhav set up the Firebase project, chose the resident features (bee sound, sighting report), picked the map style and tested each build on phone and web. | Live camera → relay → app verified; officer login, resident sign-up, report round-trip and Excel export checked on the web build. Open-database security gap noted, not fixed. |
| 2026-10-25 03:50 IST | Devin | Docs sync for v1.0.9 | `README.md`, `SUBMISSION.md`, `CHANGELOG.md`, `AI_USAGE.md` rewritten for the new features and limitations. | Pending Madhav's review in PR #1. | Claims re-checked against the code and flow JSON. |

## Notes

- No AI usage is claimed beyond the rows above. Problem choice, product framing, hardware setup, phone testing and all decisions were Madhav's.
- No secrets, QR codes or private participant data were given to the agent or committed.

## Template preparation (organizer)

On 10 October 2026 the organizer's template docs (`README.md`, `RULES.md`, `AGENTS.md`, `CHANGELOG.md`, `AI_USAGE.md`, `SUBMISSION.md`, `.gitignore`, PR checklist) were prepared with Codex. That is separate from participant AI usage above.
