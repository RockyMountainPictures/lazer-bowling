import processing.serial.*;
import java.util.Arrays;
/*
IAT 267 - Toy Hack Project
Toy: Table Top Bowling
Date: 26-02-2023
By: Max Nielsen

Description: Adds a bowling monitor for a tabletop bowling set.
             Records your points with up to 4 players and 10 rounds.
             Uses photoresistors to detect if a pin has fallen.
             Displays scores on a screen, and the current pins standing with some LEDs.
             Buttons to reset, start bowling, go to the next player, and go to the next round.
             Uses processing to manage score.
*/ 

// --- Variables --- //
// Arduino
String portName = "COM8";
Serial port;
static String rx;

// Val: 1 = button states, 2 = current state, 3 = current turn points.
final int numValues = 3;
int[] rxVal = new int[numValues];
int[] val = new int[numValues];
int[] prevVal = new int[numValues];

/*
val will contain all the necessary information to be received form Processing. (3 ints total)
- button states (to reset, to start bowling, to move to next player, to move to next round) (int from 0-4)
- current state (bowling, switch to next player, switched to next round) (int from 0-3)
- current bowl points (int from 0-15)
*/

// Processing
PVector screenSize = new PVector(320*4, 240*4);
ArrayList<Player> players = new ArrayList<Player>();
int numPlayers = 1;
int maxPlayers = 4;
int numRounds = 5;
int currRound, currTurn;
Player currPlayer;
Player highScorer;
int currPlayerNum = 0;
int num = 0;

// Fonts
PFont regFont;
PFont boldFont;

// Frame
byte[] prevFrameTx = new byte[int(screenSize.x*screenSize.y)];
byte[] frameTx = new byte[int(screenSize.x*screenSize.y)];
String frameTxStart = "S: ";

void settings() {
  size((int)screenSize.x, (int)screenSize.y);
  noSmooth();
}

void setup() {
  background(0);
  // Fonts
  regFont = createFont("Cooper Black", 12, false);
  boldFont = createFont("OCR A Extended", 16, false);
  port = new Serial(this, portName, 9600);
  for(int i = 0; i < numPlayers; i++)
    players.add(new Player(numRounds));
  currRound = 0;
  currTurn = -1;
  currPlayer = players.get(currPlayerNum);
}

void draw() {
  scale(4.0);
  drawScoreboard();
  readSerial();
  if(rxVal != prevVal) {  // Only update if things have changed
    //printValues();
    updateData();
    sendSerial();
  }
  sendFrame();
  //val[1] = 1;
}

void sendFrame() {
  loadPixels();
  frameTx = new byte[int(screenSize.x*screenSize.y)];
  boolean send = false;
  for(int i = 0; i < pixels.length; i++) {
    if(pixels[i] == -16777216)  // Black Decimal
      frameTx[i] = 0;
    else if(pixels[i] == -1)  // White Decimal
      frameTx[i] = 1;
    else if(pixels[i] == -2163490)  // Light Green Decimal
      frameTx[i] = 2;
    else if(pixels[i] == -14029497)  // Green Decimal
      if(frameTx[i] != 3)
        frameTx[i] = 3;
    if(frameTx[i] != prevFrameTx[i])
      send = true;
  }
  if(send) {
    //port.write(frameTxStart);
    //port.write(tx);
    prevFrameTx = frameTx;
  }
  
  updatePixels();
}

void calculateHighScore() {
  highScorer = players.get(0);
  for(int i = 0; i < players.size(); i++) {
    if(players.get(i).finalScore > highScorer.finalScore)
      highScorer = players.get(i);
  }
}

void readSerial() {
  if(port.available() > 0) {
    rx = port.readStringUntil('\n');
    if(rx != null) {
      rx = rx.trim();
      if(rx.charAt(0) == 'A') {  // Only check for Arduino's serial outputs
        rx = rx.replaceAll("A: ", "");  // Removes the prefix to the serial output
        //println(rx);
        try {
          rxVal = Arrays.stream(rx.split("-")).mapToInt(Integer::parseInt).toArray();
        }
        catch (Exception e) {
          println("ERROR");
        }
      }
    }
  }
}

void sendSerial() {
  String tx = "P: ";
  for(int i = 0; i < numValues; i++)
    tx += val[i] + "-";
  tx = tx.substring(0, tx.length() - 2);  // Removes last dash
  //port.write(tx);
}

void printValues() {
  print("values ");
  for(int i = 0; i < numValues; i++)
    print(rxVal[i] + " ");
  println("from arduino.");
}

void updateData() {
  val = rxVal;
  //println(currTurn);
  // Button States
  if(val[0] != 0) {  // Only execute once
    switch(val[0]) {
      case 0:
        // Do nothing. No button has been pressed
        break;
      case 1:
        // reset game
        reset();
        break;
      case 2:
        // Set current state to currently bowling
        switch(currTurn) {  // Change players if the last turn of the current player
          case -1:
            currTurn++;
            val[1] = 1;
            break;
          case 0: 
            nextTurn();
            val[1] = 1;
            break;
          case 1:
            nextTurn();
            val[1] = 1;
            break;
          //case 2:
          //  nextPlayer();
          //  break;
          }
        break;
      case 3:
        // Switch to the next player up to bowl
        nextPlayer();
        break;
      case 4:
        // Switch to the next round
        nextRound();
        break;
    }
    val[0] = 0;  // Set button to zero as we have executed the button press
  }
  // Current State
  switch(val[1]) {
    case 0:
      // Do nothing, it's the start of the game probably
      break;
    case 1:
      // Collect and update bowling data
      if(currTurn <= 2 && currTurn >= 0)
        currPlayer.setTurnScore(val[2]);
      break;
    case 2:
      // In between player turns. Do nothing for now
      break;
    case 3:
      // In between bowling rounds. Do nothing for now
      break;
  }
  prevVal = val;
}

void drawScoreboard() {
  drawBG();
  for(int i = 0; i < players.size(); i++)
   players.get(i).drawMe(i);
}

void drawBG() {
 background(0);
 textFont(boldFont, 16);
 textAlign(CENTER, BOTTOM);
 //text("THE BOWLING GAME", screenSize.x/2, 20); 
}

void nextPlayer() {
  //currPlayer.setTurnScore(val[2]);
  currPlayer.calcRoundScore();
  currPlayer.calcTotalScore();
  val[2] = 0;
  
  if(currRound == 0 && players.size() <= maxPlayers)
    players.add(new Player(numRounds));
  if(currPlayerNum > players.size())
    nextRound();
  else
    currPlayerNum++;
  if(currPlayerNum >= players.size())
    nextRound();
  else
    currPlayer = players.get(currPlayerNum);
  currTurn = -1;
}

void nextTurn() {
  //currPlayer.setTurnScore(val[2]);
  currTurn++;
  val[1] = 0;
}

void nextRound() {
  currPlayer.calcRoundScore();
  currPlayer.calcTotalScore();
  if(currRound + 1 == numRounds)
    calculateHighScore();
  else
    currRound++;
  currPlayerNum = 0;
  currPlayer = players.get(currPlayerNum);
  currTurn = -1;
  val[1] = 0;
}

void reset() {
  players.clear(); 
  currPlayerNum = 0;
  for(int i = 0; i < numPlayers; i++)
    players.add(new Player(numRounds));
  currRound = 0;
  currTurn = -1;
  currPlayer = players.get(currPlayerNum);
  rxVal = new int[numValues];
  val = new int[numValues];
  prevVal = new int[numValues];
}
