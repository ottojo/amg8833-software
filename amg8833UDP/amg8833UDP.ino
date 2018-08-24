#include <Wire.h>
#include <Adafruit_AMG88xx.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>

#define MINTEMP 10
#define MAXTEMP 50

const char* ssid = "Toolbox";
const char* password = "WIFIPASSWORD";

WiFiUDP Udp;
unsigned int localUdpPort = 4210;

float pixels[AMG88xx_PIXEL_ARRAY_SIZE];
Adafruit_AMG88xx amg;



void setup()
{
  Serial.begin(115200);

  Serial.printf("Connecting to %s ", ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.print(".");
  }
  Serial.println(" connected");

  Udp.begin(localUdpPort);

  bool status;
  // default settings
  status = amg.begin(0x68);
  if (!status) {
    Serial.println("Could not find a valid AMG88xx sensor, check wiring!");
    while (1);
  }
  delay(100);
}


void loop() {
  amg.readPixels(pixels);

  unsigned char buf[AMG88xx_PIXEL_ARRAY_SIZE];
  for (int i = 0; i < AMG88xx_PIXEL_ARRAY_SIZE; i++) {
    buf[i] = map(pixels[i], MINTEMP, MAXTEMP, 0, 255);
    buf[i] = constrain(buf[i] , 0, 255);
    Serial.println(pixels[i], DEC);
  }

  Udp.beginPacketMulticast(IPAddress(239, 1, 3, 38), 1339, WiFi.localIP());
  Udp.write(buf, AMG88xx_PIXEL_ARRAY_SIZE);
  Udp.endPacket();

  delay(100);
}
