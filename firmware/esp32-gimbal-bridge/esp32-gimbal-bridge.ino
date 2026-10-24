// Kaval watch post - ESP32 gimbal + siren bridge
// ESP32 hosts the Wi-Fi AP (same as Oozham): camera joins at 192.168.4.2.
// Polls the reCamera Node-RED API over HTTP/1.0:
//   GET /api/gimbal  -> "pan,tilt"  (degrees)  -> two servos
//   GET /api/watcher -> JSON with "alert":true  -> siren/flood-light relay
#include <WiFi.h>
#include <HTTPClient.h>
#include <ESP32Servo.h>

const char* AP_SSID = "Kaval-Post";
const char* AP_PASS = "kaval1234";
const char* GIMBAL_URL = "http://192.168.4.2:1880/api/gimbal";
const char* WATCH_URL  = "http://192.168.4.2:1880/api/watcher";

const int PAN_PIN   = 13;   // servo signal
const int TILT_PIN  = 12;   // servo signal
const int RELAY_PIN = 14;   // siren / flood light relay (active HIGH)
const int LED_PIN   = 2;    // on-board LED mirrors alert

Servo pan, tilt;
int curPan = 90, curTilt = 90;
unsigned long lastPoll = 0;

String httpGet(const char* url) {
  HTTPClient http;
  http.setTimeout(8000);
  http.useHTTP10(true);
  http.begin(url);
  http.addHeader("Connection", "close");
  int code = http.GET();
  String body = (code == 200) ? http.getString() : "";
  http.end();
  return body;
}

void moveTowards(int& cur, int target, Servo& s) {
  if (target < 0 || target > 180) return;
  if (cur < target) cur = min(cur + 4, target);
  else if (cur > target) cur = max(cur - 4, target);
  s.write(cur);
}

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT); digitalWrite(RELAY_PIN, LOW);
  pinMode(LED_PIN, OUTPUT);
  pan.attach(PAN_PIN, 500, 2400);
  tilt.attach(TILT_PIN, 500, 2400);
  pan.write(curPan); tilt.write(curTilt);
  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);
  Serial.print("AP up, IP: "); Serial.println(WiFi.softAPIP());
}

void loop() {
  if (millis() - lastPoll < 250) return;
  lastPoll = millis();

  String g = httpGet(GIMBAL_URL);           // "pan,tilt"
  int comma = g.indexOf(',');
  if (comma > 0) {
    int p = g.substring(0, comma).toInt();
    int t = g.substring(comma + 1).toInt();
    moveTowards(curPan, p, pan);
    moveTowards(curTilt, t, tilt);
  }

  static unsigned long lastWatch = 0;
  if (millis() - lastWatch > 1000) {        // alert state once a second
    lastWatch = millis();
    String w = httpGet(WATCH_URL);
    bool alert = w.indexOf("\"alert\":true") >= 0;
    digitalWrite(RELAY_PIN, alert ? HIGH : LOW);
    digitalWrite(LED_PIN, alert ? HIGH : LOW);
    Serial.printf("pan %d tilt %d alert %d\n", curPan, curTilt, alert);
  }
}
