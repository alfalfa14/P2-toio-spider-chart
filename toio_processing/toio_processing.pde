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

int nCubes = 5;
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

int p = 0;

// -------- MENU FEATURE --------

boolean showingMenu = true;
boolean playerSelected = false;

int selectedRow = 0;
int visibleRows = 8;

boolean[] prevButton;

int MENU_CUBE = 0;
int UP_CUBE = 1;
int DOWN_CUBE = 2;

int SHO_CUBE = 0;
int DRI_CUBE = 1;
int PAC_CUBE = 2;
int PAS_CUBE = 3;
int DEF_CUBE = 4;

// ---------------- DATA ----------------

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

// ---------------- SETUP ----------------

void settings() {
  fullScreen(P3D);
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

// ---------------- DRAW MAIN BACKGROUND ----------------

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

// ---------------- PROJECT DATA TO TOIOS ----------------

void projectData() {
  p = selectedRow;

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

    if (cubes[i].isActive) {
      cubes[i].target(tx, ty, cubes[i].theta);
    }
  }
}

// ---------------- MAIN DRAW ----------------

void draw() {
  long now = System.currentTimeMillis();

  for (int i = 0; i < nCubes; i++) {
    cubes[i].checkActive(now);
  }

  handleControls();

  offscreen.beginDraw();

  if (showingMenu) {
    drawMenu();
  } else {
    projectData();
    drawBackground();
    drawSpiderChartFromToios();
    drawSelectedPlayerText();
  }

  offscreen.endDraw();

  background(0);
  surface.render(offscreen);

  updatePreviousButtons();
}

// ---------------- MENU ----------------

void drawMenu() {
  offscreen.background(255, 199, 226);

  offscreen.fill(0);
  offscreen.textAlign(CENTER, CENTER);

  offscreen.textFont(boldFont);
  offscreen.textSize(22);
  offscreen.text("Select Player", surfaceW / 2, 35);

  offscreen.textFont(regularFont);
  offscreen.textSize(10);
  offscreen.text("Cube 1 = up | Cube 2 = down", surfaceW / 2, 62);
  offscreen.text("Click Cube 0 to select / open menu", surfaceW / 2, 78);

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
      offscreen.textSize(11);
      offscreen.text(player[rowIndex], surfaceW / 2, y);
    }
  }

  offscreen.textFont(regularFont);
  offscreen.textSize(9);
  offscreen.fill(0);
  offscreen.text((selectedRow + 1) + " / " + dataNum, surfaceW / 2, 395);
}

// ---------------- CONTROLS ----------------

void handleControls() {
  if (showingMenu && cubeClicked(UP_CUBE)) {
    selectedRow--;

    if (selectedRow < 0) {
      selectedRow = dataNum - 1;
    }
  }

  if (showingMenu && cubeClicked(DOWN_CUBE)) {
    selectedRow++;

    if (selectedRow >= dataNum) {
      selectedRow = 0;
    }
  }

  if (cubeClicked(MENU_CUBE)) {
    if (showingMenu) {
      showingMenu = false;
      playerSelected = true;
    } else {
      showingMenu = true;
      playerSelected = false;
    }
  }
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

// ---------------- SPIDER CHART ----------------

void drawSpiderChartFromToios() {
  color c = color(255, 253, 134, 127);

  offscreen.fill(c);
  offscreen.stroke(204, 201, 46);
  offscreen.strokeWeight(4);

  offscreen.beginShape();

  for (int i = 0; i < nCubes; i++) {
    if (cubes[i].isActive) {
      float pointX = map(cubes[i].x, matDimension[0], matDimension[2], 0, surfaceW);
      float pointY = map(cubes[i].y, matDimension[1], matDimension[3], 0, surfaceH);

      offscreen.vertex(pointX, pointY);
    }
  }

  offscreen.endShape(CLOSE);
}

// ---------------- PLAYER TEXT ----------------

void drawSelectedPlayerText() {
  offscreen.fill(0);
  offscreen.noStroke();
  offscreen.textAlign(CENTER, CENTER);

  offscreen.textFont(boldFont);
  offscreen.textSize(14);
  offscreen.text(player[selectedRow], surfaceW / 2, 340);

  offscreen.textFont(regularFont);
  offscreen.textSize(10);

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
