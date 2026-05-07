import oscP5.*;
import netP5.*;
import deadpixel.keystone.*;

Keystone ks;
CornerPinSurface surface;
PGraphics offscreen;
PImage bg;

PFont regularFont;
PFont boldFont;

int surfaceW = 410;
int surfaceH = 410;

int nCubes = 8;
int shapeCubes = 5;
int cubesPerHost = 12;
int maxMotorSpeed = 115;
int xOffset;
int yOffset;

boolean WindowsMode = false;
int framerate = 30;

int[] matDimension = {45, 45, 455, 455};

OscP5 oscP5;
NetAddress[] server;
Cube[] cubes;

// data
Table table;
int dataNum = 0;
int loadingFileID = 0;
int maxLoadingFileNum = 0;

String[] player;
int[] rank;
int[] ovr;
int[] sho;
int[] dri;
int[] pac;
int[] pas;
int[] def;

// circle
float cx = surfaceW / 2;
float cy = 200;
float circleSize = 300;
float r = circleSize / 2;

float[] angles = {
  radians(-90),
  radians(-18),
  radians(54),
  radians(126),
  radians(198)
};

// player index
int p = 0;

// bool to determine if cubes need a signal to move or not
boolean needsUpdate = true;

// menu vars
boolean showingMenu = true;
boolean playerSelected = false;

int selectedRow = 0;
int visibleRows = 8;

boolean[] prevButton;


// stat cubes
int SHO_CUBE = 0;
int DRI_CUBE = 1;
int PAC_CUBE = 2;
int PAS_CUBE = 3;
int DEF_CUBE = 4;

// menu control cubes
int SELECT_CUBE = 5;
int MENU_CUBE = 6;
int SCROLL_CUBE = 7;

// rotation tracking
float lastScrollTheta = 0;
boolean scrollThetaInitialized = false;
int lastRotateTime = 0;
int rotateCooldown = 300;

// data processing

void loadData() {
  table = loadTable("data/EAFC26.csv", "header");

  dataNum = table.getRowCount();
  println("dataNum is " + dataNum);

  player = new String[dataNum];
  rank = new int[dataNum];
  ovr = new int[dataNum];
  sho = new int[dataNum];
  dri = new int[dataNum];
  pac = new int[dataNum];
  pas = new int[dataNum];
  def = new int[dataNum];

  int rowCount = 0;

  for (TableRow row : table.rows()) {
    player[rowCount] = row.getString("Name");
    rank[rowCount] = row.getInt("Rank");
    ovr[rowCount] = row.getInt("OVR");
    sho[rowCount] = row.getInt("SHO");
    dri[rowCount] = row.getInt("DRI");
    pac[rowCount] = row.getInt("PAC");
    pas[rowCount] = row.getInt("PAS");
    def[rowCount] = row.getInt("DEF");
    rowCount++;
  }
}

// setup

void settings() {
  fullScreen(P3D, 2);
  pixelDensity(1);
}

void setup() {
  oscP5 = new OscP5(this, 3333);

  server = new NetAddress[1];
  server[0] = new NetAddress("127.0.0.1", 3334);

  cubes = new Cube[nCubes];

  for (int i = 0; i < nCubes; ++i) {
    cubes[i] = new Cube(i);
  }

  prevButton = new boolean[nCubes];

  xOffset = matDimension[0] - 45;
  yOffset = matDimension[1] - 45;

  frameRate(framerate);

  if (WindowsMode) {
    check_connection();
  }

  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(surfaceW, surfaceH, 20);
  offscreen = createGraphics(surfaceW, surfaceH, P3D);

  regularFont = createFont("Arial", 13);
  boldFont = createFont("Arial Bold", 13);

  loadData();
}

// main background

void drawBackground() {
  offscreen.background(255, 199, 226);

  offscreen.fill(255);
  offscreen.noStroke();
  offscreen.ellipse(cx, cy, circleSize, circleSize);

  offscreen.stroke(190);
  offscreen.strokeWeight(3);

  for (int i = 0; i < angles.length; i++) {
    float x2 = cx + cos(angles[i]) * r;
    float y2 = cy + sin(angles[i]) * r;
    offscreen.line(cx, cy, x2, y2);
  }

  offscreen.fill(0);
  offscreen.noStroke();
  offscreen.textAlign(CENTER, CENTER);
  offscreen.textFont(regularFont);
  offscreen.textSize(12);

  String[] labels = {
    "Shooting",
    "Dribbling",
    "Pace",
    "Passing",
    "Defending"
  };

  float labelRadius = r + 30;

  for (int i = 0; i < angles.length; i++) {
    float tx = cx + cos(angles[i]) * labelRadius;
    float ty = cy + sin(angles[i]) * labelRadius;
    offscreen.text(labels[i], tx, ty);
  }
}

// project data to stat toios
void projectData() {

  p = selectedRow;

  int[] statCubes = {
    SHO_CUBE,
    DRI_CUBE,
    PAC_CUBE,
    PAS_CUBE,
    DEF_CUBE
  };

  for (int i = 0; i < angles.length; i++) {
    float px = cx + cos(angles[i]) * r;
    float py = cy + sin(angles[i]) * r;

    float endX = 0;
    float endY = 0;

    switch(i) {
    case 0:
      endX = map(sho[p], 0, 100, cx, px);
      endY = map(sho[p], 0, 100, cy, py);
      break;

    case 1:
      endX = map(dri[p], 0, 100, cx, px);
      endY = map(dri[p], 0, 100, cy, py);
      break;

    case 2:
      endX = map(pac[p], 0, 100, cx, px);
      endY = map(pac[p], 0, 100, cy, py);
      break;

    case 3:
      endX = map(pas[p], 0, 100, cx, px);
      endY = map(pas[p], 0, 100, cy, py);
      break;

    case 4:
      endX = map(def[p], 0, 100, cx, px);
      endY = map(def[p], 0, 100, cy, py);
      break;
    }

    int tx = int(map(endX, 0, surfaceW, matDimension[0], matDimension[2]));
    int ty = int(map(endY, 0, surfaceH, matDimension[1], matDimension[3]));

    int cubeID = statCubes[i];

    if (cubes[cubeID].isActive) {
      cubes[cubeID].target(tx, ty, cubes[cubeID].theta);
    }
  }
  needsUpdate = false;
}

void moveStatCubesToMenuEdges() {
  int[] statCubes = {
    SHO_CUBE,
    DRI_CUBE,
    PAC_CUBE,
    PAS_CUBE,
    DEF_CUBE
  };

  int margin = 35;

  for (int i = 0; i < statCubes.length; i++) {
    int cubeID = statCubes[i];

    float surfaceX = cx + cos(angles[i]) * (r + 55);
    float surfaceY = cy + sin(angles[i]) * (r + 55);

    surfaceX = constrain(surfaceX, margin, surfaceW - margin);
    surfaceY = constrain(surfaceY, margin, surfaceH - margin);

    int targetMatX = int(map(surfaceX, 0, surfaceW, matDimension[0], matDimension[2]));
    int targetMatY = int(map(surfaceY, 0, surfaceH, matDimension[1], matDimension[3]));

    if (cubes[cubeID].isActive && cubes[cubeID].x != targetMatX + 5 && cubes[cubeID].y != targetMatY) {
      cubes[cubeID].target(targetMatX, targetMatY, cubes[cubeID].theta);
    }
  }
  needsUpdate = false;
}

// main draw
void draw() {
  long now = System.currentTimeMillis();

  for (int i = 0; i < nCubes; i++) {
    cubes[i].checkActive(now);
  }

  handleControls();

  offscreen.beginDraw();

  if (showingMenu) {
    drawMenu();
    if (needsUpdate) {
      moveStatCubesToMenuEdges();
    }
  } else {
    if (needsUpdate) {
      projectData();
    }
    drawBackground();
    drawSpiderChartFromToios();
    drawSelectedPlayerText();
  }

  offscreen.endDraw();

  background(0);
  surface.render(offscreen);

  updatePreviousButtons();
}

// draw the menu
void drawMenu() {
  offscreen.background(255, 199, 226);

  offscreen.fill(0);
  offscreen.textAlign(CENTER, CENTER);

  offscreen.textFont(boldFont);
  offscreen.textSize(22);
  offscreen.text("Select Player", surfaceW / 2, 35);

  offscreen.textFont(regularFont);
  offscreen.textSize(14);
  //offscreen.text("Cube 1 = up | Cube 2 = down", surfaceW / 2, 62);
  //offscreen.text("Click Cube 0 to select / open menu", surfaceW / 2, 78);
  offscreen.textSize(10);
  offscreen.text("Rotate Cube 7 to scroll players", surfaceW / 2, 62);
  offscreen.text("Cube 5 = select | Cube 6 = menu", surfaceW / 2, 78);

  int rowH = 31;
  int startRow = selectedRow - visibleRows / 2;

  if (startRow < 0) {
    startRow = 0;
  }

  if (startRow > dataNum - visibleRows) {
    startRow = max(0, dataNum - visibleRows);
  }

  for (int i = 0; i < visibleRows; i++) {
    int rowIndex = startRow + i;

    if (rowIndex >= dataNum) {
      break;
    }

    int y = 115 + i * rowH;

    if (rowIndex == selectedRow) {
      offscreen.fill(255);
      offscreen.stroke(0);
      offscreen.strokeWeight(2);
      offscreen.rect(35, y - 14, surfaceW - 70, 25, 8);

      offscreen.fill(0);
      offscreen.noStroke();
      offscreen.textFont(boldFont);
      offscreen.textSize(12);
      offscreen.text("> " + player[rowIndex], surfaceW / 2, y);
    } else {
      offscreen.fill(0);
      offscreen.noStroke();
      offscreen.textFont(regularFont);
      offscreen.textSize(12);
      offscreen.text(player[rowIndex], surfaceW / 2, y);
    }
  }

  offscreen.textFont(regularFont);
  offscreen.textSize(12);
  offscreen.fill(0);
  offscreen.text((selectedRow + 1) + " / " + dataNum, surfaceW / 2, 395);
}

// controls

void handleControls() {
  detectScrollTwist();

  if (cubeClicked(MENU_CUBE)) {
    if (showingMenu) {
      showingMenu = false;
      playerSelected = true;
      needsUpdate = true;
    } else {
      showingMenu = true;
      playerSelected = false;
      needsUpdate = true;
    }
    showingMenu = !showingMenu;
    playerSelected = !showingMenu;
  }

  if (showingMenu && cubeClicked(SELECT_CUBE)) {
    showingMenu = false;
    playerSelected = true;
  }
}

void detectScrollTwist() {
  if (!showingMenu) {
    return;
  }

  if (!cubes[SCROLL_CUBE].isActive) {
    return;
  }

  float currentTheta = cubes[SCROLL_CUBE].theta;

  if (!scrollThetaInitialized) {
    lastScrollTheta = currentTheta;
    scrollThetaInitialized = true;
    return;
  }

  float diff = angleDifference(currentTheta, lastScrollTheta);

  if (abs(diff) > 5 && millis() - lastRotateTime > rotateCooldown) {
    if (diff < 0) {
      selectedRow--;

      if (selectedRow < 0) {
        selectedRow = dataNum - 1;
      }
    } else {
      selectedRow++;

      if (selectedRow >= dataNum) {
        selectedRow = 0;
      }
    }

    lastRotateTime = millis();
  }

  lastScrollTheta = currentTheta;
}

float angleDifference(float a, float b) {
  return (a - b + 540) % 360 - 180;
}

boolean cubeClicked(int idx) {
  if (idx < 0 || idx >= nCubes) {
    return false;
  }

  return cubes[idx].buttonDown && !prevButton[idx];
}

void updatePreviousButtons() {
  for (int i = 0; i < nCubes; i++) {
    prevButton[i] = cubes[i].buttonDown;
  }
}

// draw chart
void drawSpiderChartFromToios() {
  color c = color(255, 253, 134, 127);

  offscreen.fill(c);
  offscreen.stroke(204, 201, 46);
  offscreen.strokeWeight(4);

  offscreen.beginShape();


  for (int i = 0; i < shapeCubes; i++) {
    if (cubes[i].isActive) {
      float pointX = map(cubes[i].x, matDimension[0], matDimension[2], 0, surfaceW);
      float pointY = map(cubes[i].y, matDimension[1], matDimension[3], 0, surfaceH);

  int[] statCubes = {
    SHO_CUBE,
    DRI_CUBE,
    PAC_CUBE,
    PAS_CUBE,
    DEF_CUBE
  };


  offscreen.endShape(CLOSE);
  }
 }
}

// draw selected player text
void drawSelectedPlayerText() {
  offscreen.fill(0);
  offscreen.noStroke();
  offscreen.textAlign(CENTER, CENTER);

  offscreen.textFont(boldFont);
  offscreen.textSize(14);
  offscreen.text(player[selectedRow], surfaceW / 2, 360);

  offscreen.textFont(regularFont);
  offscreen.textSize(12);

  String statText =
    "Rank " + rank[selectedRow] +
    " | OVR " + ovr[selectedRow] +
    " | SHO " + sho[selectedRow] +
    " | DRI " + dri[selectedRow] +
    " | PAC " + pac[selectedRow] +
    " | PAS " + pas[selectedRow] +
    " | DEF " + def[selectedRow];

  offscreen.text(statText, surfaceW / 2, 365);
}
