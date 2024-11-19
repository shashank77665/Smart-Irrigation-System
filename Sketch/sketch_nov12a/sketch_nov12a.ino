#include <WiFi.h>
#include <FirebaseESP32.h>

// Firebase project details
FirebaseConfig config;
FirebaseAuth auth;

// WiFi credentials
#define WIFI_SSID "261c"
#define WIFI_PASSWORD "Netplus1234"

// Firebase credentials
#define FIREBASE_HOST "iot-project-5d401-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "AIzaSyDB9BKkfuWHmgmMijGQxe9rwT7zAyx-Awk"

// Firebase Data object
FirebaseData firebaseData;

// Relay GPIO pin (using GPIO 23 for the pump)
#define PUMP_PIN 23
#define SOIL_MOISTURE_THRESHOLD 300  // Set a suitable threshold based on your sensor's calibration

// Firebase paths
String manualControlTogglePath = "/controls/manualControlToggle";
String pumpStatePath = "/controls/pumpState";
String soilMoisturePath = "/sensors/soilMoisture"; // New path for soil moisture data

void setup() {
  Serial.begin(9600);

  Serial.println(F("Starting ESP32..."));

  pinMode(PUMP_PIN, OUTPUT);

  // Initialize pump state to LOW (OFF)
  digitalWrite(PUMP_PIN, LOW);

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print(F("Connecting to Wi-Fi"));

  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(F("."));
    delay(500);
  }

  Serial.println(F("\nConnected to Wi-Fi"));
  Serial.println(F("IP Address:"));
  Serial.println(WiFi.localIP());

  // Firebase configuration
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println(F("Connected to Firebase!"));
}
void loop() {
  // Fetch the status of manual control from Firebase every loop
  bool manualControlToggle = false;
  if (Firebase.get(firebaseData, manualControlTogglePath)) {
    if (firebaseData.dataType() == "boolean") {
      manualControlToggle = firebaseData.boolData();
      Serial.print(F("Manual Control Toggle: "));
      Serial.println(manualControlToggle ? "ON" : "OFF");
    } else {
      Serial.println(F("Failed to retrieve manual control toggle."));
    }
  } else {
    Serial.print(F("Failed to read manual control toggle from Firebase: "));
    Serial.println(firebaseData.errorReason());
  }

  if (manualControlToggle) {
    // Manual control: Read pumpState from Firebase
    bool pumpState = false;
    if (Firebase.get(firebaseData, pumpStatePath)) {
      if (firebaseData.dataType() == "boolean") {
        pumpState = firebaseData.boolData();
        Serial.print(F("Pump State: "));
        Serial.println(pumpState ? "ON" : "OFF");

        // Control the pump based on the pumpState value from Firebase (flip the logic)
        digitalWrite(PUMP_PIN, pumpState ? LOW : HIGH);  // Reversed logic

        // Update pump state to Firebase
        Firebase.setBool(firebaseData, pumpStatePath, pumpState);
      } else {
        Serial.println(F("Failed to retrieve pump state."));
      }
    } else {
      Serial.print(F("Failed to read pump state from Firebase: "));
      Serial.println(firebaseData.errorReason());
    }
  } else {
    // Fetch soil moisture value from Firebase
    int soilMoisture = 0;
    if (Firebase.get(firebaseData, soilMoisturePath)) {
      if (firebaseData.dataType() == "int") {
        soilMoisture = firebaseData.intData();
        Serial.print(F("Soil Moisture from Firebase: "));
        Serial.println(soilMoisture);
      } else {
        Serial.println(F("Failed to retrieve soil moisture from Firebase."));
      }
    } else {
      Serial.print(F("Failed to read soil moisture from Firebase: "));
      Serial.println(firebaseData.errorReason());
    }

    // Automatic mode: Control pump based on soil moisture value
    bool pumpState = false;
    if (soilMoisture < SOIL_MOISTURE_THRESHOLD) {
      digitalWrite(PUMP_PIN, LOW);  // Turn pump ON (inversely)
      Serial.println(F("Soil moisture is low. Pump is ON."));
      pumpState = true;  // Set pump state to ON
    } else {
      digitalWrite(PUMP_PIN, HIGH);  // Turn pump OFF (inversely)
      Serial.println(F("Soil moisture is adequate. Pump is OFF."));
      pumpState = false;  // Set pump state to OFF
    }

    // Optionally, update the Firebase with the new pump state after automatic control
    Firebase.setBool(firebaseData, pumpStatePath, pumpState);
  }

  // Wait before the next check
  delay(1000);
}
