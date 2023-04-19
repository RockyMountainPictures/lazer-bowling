/*  Resources:
      How to split strings into an array: https://forum.arduino.cc/t/how-to-split-a-string-with-space-and-store-the-items-in-array/888813/8
*/


const int numPins = 5;
const int numBtns = 4;
int sensPin[] = {A4, A3, A2, A1, A0};  // Top, Middle-Left, Middle-Right, Bottom-Left, Bottom-Right
int ledPin[] = {2, 3, 4, 5, 6};  // Top, Middle-Left, Middle-Right, Bottom-Left, Bottom-Right
int btnPin[] = {8, 9, 10, 11};  // Reset, Bowl, Next Player, Next Round
bool btnValues[numBtns][2]; // 1: Current value, 2: previous value
int sensValues[numPins];  // raw value of photocell
int pinValues[numPins][3]; // [pin ID][isKnocked, points, switchBrightness]
float sensitivity = .80; // Percent of how much light there should be to switch states. 0-1: Lower = Changes at lower brightness value
int maxBrightness, minBrightness;
int switchBrightness;


// Val: 0 = button states, 1 = current state, 2 = current turn points. 
String rx;
const int numValues = 3;
int rxVal[numValues];
int val[numValues];
int prevVal[numValues];

// Screen Values
const int pixelCount = 320 * 240;
unsigned int pixels[1];


void setup() {
  Serial.begin(9600);
  for(int i = 0; i < numPins; i++) {
    pinMode(sensPin[i], INPUT);
    pinMode(ledPin[i], OUTPUT);
    pinValues[i][0] = 0;
    digitalWrite(ledPin[i], HIGH);
    switch(i) {
      case 0:
        pinValues[i][1] = 5;
        break;
      case 1: case 2:
        pinValues[i][1] = 3;
        break;
      case 3: case 4:
        pinValues[i][1] = 2;
        break;
    }
  }

  for(int i = 0; i < numBtns; i++) {
    pinMode(btnPin[i], INPUT);
    btnValues[i][0] = 0;
    btnValues[i][1] = 0;
  }

  calibrateSensors();
}

void loop() {
  delay(30);
  readSerial();
  if(rxVal != prevVal) {
    //printValues();
    
  }
  handleInputs();
  sendSerial();
  //val[1] = 2;
  if(val[1] == 1)
    handleBowling();
  memcpy(prevVal, val, sizeof(val));
}

// Handle button presses
void handleInputs() {
  for(int i = 0; i < numBtns; i++) {  // Read values and assign accordingly
    btnValues[i][0] = digitalRead(btnPin[i]);
    if(btnValues[i][0] == 0 && btnValues[i][0] != btnValues[i][1]) {  // Ensure action executes on button release
      val[0] = i + 1;
      break;
    }
    else
      val[0] = 0;
  }

  switch(val[0]) {  // Execute button press actions required by Arduino
    case 1:
      // Reset arduino-related things
      Serial.println("RESET");
      reset();
      break;
    case 2:
      val[1] = 1;
      val[2] = 0;
      Serial.println("BOWL");
      // Bowl
      break;
    case 3:
      val[1] = 2;
      Serial.println("NEXT PLAYER");
      for(int i = 0; i < numPins; i++) {
        pinValues[i][0] = 0;
        digitalWrite(ledPin[i], HIGH);
        calibrateSensors();
      }
      // Next Player
      break;
    case 4:
      val[1] = 3;
      Serial.println("NEXT ROUND");
      val[2] = 0;
      for(int i = 0; i < numPins; i++) {
        pinValues[i][0] = 0;
        digitalWrite(ledPin[i], HIGH);
        calibrateSensors();
      }
      // Next Round
      break;
  }

  for(int i = 0; i < numBtns; i++)  // Save values to be checked next tick
      btnValues[i][1] = btnValues[i][0];
}


void sendSerial() {
  String tx = "A: ";
  for(int i = 0; i < numValues; i++) {
    tx.concat(val[i]);
    tx.concat("-");
  }
  tx.remove(tx.length() - 1);
  Serial.println(tx);
}


void readSerial() {
  if(Serial.available() > 0) {
    rx = Serial.readStringUntil('\n');
    rx.trim();
    if(rx.charAt(0) == 'P') {  // Only check for Processing's serial outputs
      rx.replace("P: ", "");  // Removes the prefix to the serial output
      int index = 0;
      while(index < numValues) {
        int cut = rx.indexOf('-');
        if(cut != -1) {
          rxVal[index] = rx.substring(0, cut).toInt();
          rx.substring(cut + 1);
          index++;
        }
      }
      memcpy(val, rxVal, sizeof(rxVal));
    }
    else if(rx.charAt(0) == 'S') {
      rx = Serial.readStringUntil('\n');
      rx.trim();
      int index = 0;
      while(index < pixelCount) {
        int cut = rx.indexOf(' ');
        if(cut != -1) {
          int col = rx.substring(0, cut).toInt();
          rx.substring(cut + 1);
          
          /*switch(col) {
            case 0:
              pixels[index] = color565(0, 0, 0);
              break;
            case 1:
              pixels[index] = color565(255, 255, 255);
              break;
            case 2:
              pixels[index] = color565(222, 252, 222);
              break;
            case 3:
              pixels[index] = color565(41, 237, 71);
              break;            
          }      */    
          index++;
        }
      }
    }
  }
}

void printValues() {
  Serial.print("values ");
  for(int i = 0; i < numValues; i++)
    Serial.print(rxVal[i] + " ");
  Serial.println("from processing.");
}

void handleBowling() {
  for(int i = 0; i < numPins; i++) {  // Check sensor values
    sensValues[i] = analogRead(sensPin[i]);

    if(sensValues[i] > pinValues[i][2] && pinValues[i][0] != 1) {
      digitalWrite(ledPin[i], LOW);
      val[2] += pinValues[i][1];
      pinValues[i][0] = 1;
      //Serial.println(i);
    }
    //delay(1000);
    /*Serial.print("PIN: ");
    Serial.print(i);
    Serial.print(" | VALUE: ");
    Serial.println(sensValues[i]); */ 
  }
}

void calibrateSensors() {
  int step = 0;
  for(int i = 0; i < numPins; i++) {
    int sensVal = analogRead(sensPin[i]);
    pinValues[i][2] = sensVal/sensitivity;
  }
}
  //min = map(min, 0, max, 0, 255);
  //switchBrightness = int(max / sensitivity);
  /*Serial.print("Switch Bright: ");
  Serial.println(switchBrightness);
  Serial.print("MIN: ");
  Serial.println(min);*/
  //minBrightness = min;
  //return max;

void reset() {
  calibrateSensors();
  for(int i = 0; i < numPins; i++) {
    pinValues[i][0] = 0;
    digitalWrite(ledPin[i], HIGH);
  }
  for(int i = 0; i < numBtns; i++) {
    btnValues[i][0] = 0;
    btnValues[i][1] = 0;
  }
  val[1] = 0;
  val[2] = 0;
}