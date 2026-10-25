// Kaval LoRa transmitter — Seeed XIAO + RYLR998 (camera node, post KDN-01)
// Reads the alert pin and sends 'H' over LoRa while it is HIGH.
// Same RYLR998 setup Madhav has used before: 115200 baud, address 0, network 10.

#include <SoftwareSerial.h>

#define LORA_RX_PIN 9     // XIAO pin wired to RYLR998 TX
#define LORA_TX_PIN 10    // XIAO pin wired to RYLR998 RX
#define ALERT_PIN   2     // HIGH while the camera node reports an alert

SoftwareSerial loraSerial(LORA_RX_PIN, LORA_TX_PIN);

const int LORA_ADDRESS    = 0;
const int LORA_NETWORK_ID = 10;
const unsigned long SEND_EVERY_MS = 250;

unsigned long lastSend = 0;

void sendAT(const String &cmd) {
  loraSerial.print(cmd);
  loraSerial.print("\r\n");
  delay(500);
  while (loraSerial.available()) Serial.write(loraSerial.read());
}

void setup() {
  Serial.begin(115200);
  loraSerial.begin(115200);
  pinMode(ALERT_PIN, INPUT_PULLDOWN);
  delay(1000);
  sendAT("AT+ADDRESS=" + String(LORA_ADDRESS));
  sendAT("AT+NETWORKID=" + String(LORA_NETWORK_ID));
  Serial.println("Kaval LoRa TX ready");
}

void loop() {
  if (digitalRead(ALERT_PIN) == HIGH && millis() - lastSend >= SEND_EVERY_MS) {
    lastSend = millis();
    loraSerial.print("AT+SEND=");
    loraSerial.print(LORA_ADDRESS);
    loraSerial.print(",1,H\r\n");
    Serial.println("ALERT -> sent H");
    delay(50);
    while (loraSerial.available()) Serial.write(loraSerial.read());
  }
  delay(20);
}
