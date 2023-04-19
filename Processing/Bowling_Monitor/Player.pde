class Player {
  int[][] round;
  int finalScore;
  
  // Positions and dimensions for screen
  PVector pos = new PVector(10, 10);
  
  Player(int numRounds) {
    round = new int [numRounds][4];
    for(int i = 0; i < numRounds; i++)
      round[i][3] =  0;
    calcRoundScore();
    calcTotalScore();
  }
  
  void setTurnScore(int turnScore) {
    if(round[currRound][currTurn] < turnScore)
      round[currRound][currTurn] = turnScore;
  }
  
  void calcRoundScore() {
    round[currRound][3] = 0;
    for(int i = 0; i < round[currRound].length-1; i++) {
      round[currRound][3] += round[currRound][i];
      //println(round[currRound][3]);
    }
  }
  
  void calcTotalScore() {
    finalScore = 0;
    for(int i = 0; i < round.length; i++)
      finalScore += round[i][3];
  }
  
  void drawMe(int posMult) {
    pushMatrix();
    pushStyle();
    translate(pos.x, pos.y + 55 * posMult);
    
    // Player Box
    if(currPlayer == this && val[1] == 1)
      fill(#29ED47);
    else if(currPlayer == this)
      fill(#defcde);
    else
      fill(225);
    rect(0, 0, 50, 50);
    
    //Player Name
    String title = "P" + (posMult+1);
    fill(0);
    textFont(regFont, 32);
    textAlign(CENTER, BOTTOM);
    text(title, 26, 45);
    
    // Round Boxes
    pushMatrix();
    translate(10, 0);
    for(int i = 0; i < numRounds; i++) {
      fill(0);
      stroke(255);
      translate(40, 0);
      rect(0, 1, 39, 48);
      //if(round[i] < currRound) {
        String totalRound = "" + round[i][3];
        if(currPlayer == this && currRound == i)
          fill(#29ED47);
        else
          fill(255);
        textFont(boldFont, 18);
        textAlign(CENTER, BOTTOM);
        text(totalRound, 20, 49);
      //}
    }
    
    // Total Score
    translate(40, 0);
    fill(0);
    stroke(255);
    rect(0, 1, 50, 48);
    line(50, 25, -numRounds * 40, 25);  // Horizontal Line Seperating Turn & Round Scores
    String totalGame = "" + finalScore;
    if(highScorer == this && numRounds == currRound + 1)
      fill(#29ED47);
    else
      fill(255);
    textFont(boldFont, 20);
    textAlign(CENTER, BOTTOM);
    text(totalGame, 25, 49);
    textFont(regFont, 13);
    text("TOTAL", 25.5, 21);
    popMatrix();
    
    // Turn Scores
    pushMatrix();
    translate(10, 0);
    for(int i = 0; i < numRounds; i++) {
      translate(40, 0);
      pushMatrix();
      fill(255);
      for(int j = 0; j < 3; j++) {
        translate(13.33333, 0);
        line(0, 1, 0, 24);
        //if(round[i] < currRound) {
          String totalTurn = "" + round[i][j];
          if(currPlayer == this && currTurn == j && currRound == i && val[1] == 1) {
            fill(#29ED47);
           // println(color(#29ED47));
          }
          else
            fill(255);
          textFont(boldFont, 11);
          textAlign(CENTER, BOTTOM);
          if(round[i][j] > 10)
            text(totalTurn, -7.75, 25);
          else 
            text(totalTurn, -7.75, 25);
        //}
      }
      popMatrix();
    }
    popMatrix();
    popStyle();
    popMatrix();
  }
}
