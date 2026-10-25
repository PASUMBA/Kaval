// Kaval LoRa receiver — Arduino Nano + RYLR998 + red LED + buzzer
// Idle: LED off, buzzer silent. While 'H' keeps arriving: LED on + buzzer on.
// RYLR998 at 115200 baud, address 0, network 10 (must match the transmitter).

#include <SoftwareSerial.h>

#define LORA_RX_PIN 4   // Nano D4 -> RYLR998 TX
#define LORA_TX_PIN 5   // Nano D5 -> RYLR998 RX
#define LED_PIN     2   // red LED (with series resistor)
#define BUZZER_PIN  3   // active buzzer

SoftwareSerial loraSerial(LORA_RX_PIN, LORA_TX_PIN);

const int LORA_ADDRESS    = 0;
const int LORA_NETWORK_ID = 10;
const unsigned long ACTIVE_TIMEOUT_MS = 1500;  // alert stays on this long after the last 'H'

unsigned long lastSignalTime = 0;
bool alertOn = false;

void sendAT(const String &cmd) {
  loraSerial.print(cmd);
  loraSerial.print("\r\n");
  delay(500);
  while (loraSerial.available()) Serial.write(loraSerial.read());
}

void setAlert(bool on) {
  alertOn = on;
  digitalWrite(LED_PIN, on ? HIGH : LOW);
  digitalWrite(BUZZER_PIN, on ? HIGH : LOW);
  Serial.println(on ? ">> ALERT: LED + buzzer ON" : "Alert cleared");
}

void setup() {
  Serial.begin(115200);
  loraSerial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  setAlert(false);
  delay(1000);
  sendAT("AT+ADDRESS=" + String(LORA_ADDRESS));
  sendAT("AT+NETWORKID=" + String(LORA_NETWORK_ID));
  Serial.println("Kaval LoRa RX ready");
}

void loop() {
  if (loraSerial.available()) {
    String line = "";
    unsigned long lastByte = millis();
    while (millis() - lastByte < 50) {
      if (loraSerial.available()) {
        char c = loraSerial.read();
        lastByte = millis();
        if (c == '\n') break;
        line += c;
      }
    }
    // Module's own +OK/+ERR replies are ignored; any other line is treated as a signal
    // (SoftwareSerial at 115200 can garble +RCV frames, so no strict parsing).
    if (line.indexOf("+OK") == -1 && line.indexOf("+ERR") == -1 && line.length() > 0) {
      lastSignalTime = millis();
      if (!alertOn) setAlert(true);
    }
  }
  if (alertOn && millis() - lastSignalTime >= ACTIVE_TIMEOUT_MS) setAlert(false);
}
