# Kaval gimbal simulation (web demo)

Live: https://pasumba.github.io/Kaval/ (served from the `gh-pages` branch; this folder is the same code kept on `main`).

Single-page 3D simulation (three.js) of the pan-tilt gimbal planned for the Kaval watch post, built to show how the camera would follow an animal or intruder before the servo hardware is fitted.

## Modes (buttons on the page)

| Button | What it does |
| --- | --- |
| Manual | drag / sliders move pan and tilt by hand |
| Auto scan | gimbal sweeps the scene on its own |
| Track animal | gimbal follows a detected target |
| Home | back to pan 90° / tilt 90° |
| Live cam | real video source instead of the simulated scene |

## Where the values come from

- **Simulation only:** targets are generated in the page.
- **PC webcam:** `getUserMedia` + TensorFlow.js `coco-ssd` in the browser detects people/animals and the gimbal tracks the box.
- **Real reCamera:** `kaval_live_stream.json` is a small Node-RED add-on for the camera flow (wire the `model` node → `live frame`). It adds `GET /api/stream.mjpg` (MJPEG video) and `GET /api/track` (latest boxes + pan/tilt JSON). The page reads them from the camera (default `http://192.168.1.50`, change in the page) and also reads the post's state from the Firebase relay (`posts/<id>.json`), so the gimbal on screen moves from **hardware values**.

## Run

Open `index.html` in a browser (no build step), or serve the folder with any static server. Internet is needed for the CDN scripts (three.js, tfjs, coco-ssd).

## Status

Simulation and tracking logic work in the browser; the physical servo gimbal (`firmware/esp32-gimbal-bridge/`) was **not** wired in the demo.
