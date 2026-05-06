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

// constants
// The soft limit on how many toios a laptop can handle is in the 10-12 range
// the more toios you connect to, the more difficult it becomes to sustain the connection
int nCubes = 5;
int cubesPerHost = 12;
int maxMotorSpeed = 115;
int xOffset;
int yOffset;

//// Instruction for Windows Users  (Feb 2. 2025) ////
// 1. Enable WindowsMode and set nCubes to the exact number of toio you are connecting.
// 2. Run Processing Code FIRST, Then Run the Rust Code. After running the Rust Code, you should place the toio on the toio mat, then Processing should start showing the toio position.
// 3. When you re-run the processing code, make sure to stop the rust code and toios to be disconnected.
// Optional: If the toio behavior is weird consider dropping the framerate.
boolean WindowsMode = false;

int framerate = 30;

int[] matDimension = {45, 45, 455, 455};

// for OSC
OscP5 oscP5;

// where to send the commands to
NetAddress[] server;

// keep the cubes here
Cube[] cubes;

// data processing
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

// circle center positioning
float cx = surfaceW / 2;
float cy = 200;
float circleSize = 300;
float r = circleSize/2;

// data angles -- sho, dri, pac, pas, def
float[] angles = {radians(-90), radians(-18), radians(54), radians(126), radians(198)};

// index of player that we are seeing the stats of
int p = 0;

void loadData() { // this is called only in setup
  // Load CSV file into a Table object
  // "header" option indicates the file has a header row
  
  table = loadTable("data/EAFC26.csv", "header"); //you can manually type in file name, which will access under the "data" folder
  
  dataNum = table.getRowCount(); //Get the number of row
  println("dataNum is " + dataNum);  // Print the number of row
  
  //prepare array according to the number of row/data
  player = new String [dataNum];
  rank = new int [dataNum];
  ovr = new int [dataNum];
  sho = new int [dataNum];
  dri = new int [dataNum];
  pac = new int [dataNum];
  pas = new int [dataNum];
  def = new int [dataNum];

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

void settings() {
  fullScreen(P3D);
}

void setup() {
  // launch OSC server
  oscP5 = new OscP5(this, 3333);
  server = new NetAddress[1];
  server[0] = new NetAddress("127.0.0.1", 3334);

  // create cubes
  cubes = new Cube[nCubes];
  for (int i = 0; i < nCubes; ++i) {
    cubes[i] = new Cube(i);
  }

  xOffset = matDimension[0] - 45;
  yOffset = matDimension[1] - 45;

  frameRate(framerate);

  if (WindowsMode) {
    check_connection();
  }

  // keystone projection
  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(surfaceW, surfaceH, 20);
  offscreen = createGraphics(surfaceW, surfaceH, P3D);

  // fonts
  regularFont = createFont("Arial", 13);
  boldFont = createFont("Arial Bold", 13);
  loadData();
}

void drawBackground() {
  offscreen.background(255, 199, 226); // pink background

  // main white circle
  offscreen.fill(255);
  offscreen.noStroke();
  offscreen.ellipse(cx, cy, circleSize, circleSize);

  // stat lines
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

  // distance slightly larger than radius so text sits outside circle
  float labelRadius = r + 30;

  for (int i = 0; i < angles.length; i++) {
    float tx = cx + cos(angles[i]) * labelRadius;
    float ty = cy + sin(angles[i]) * labelRadius;

    offscreen.text(labels[i], tx, ty);
  }
}

void projectData() {
  // the max for the map is the full length 
  for (int i = 0; i < angles.length; i++) {
    float px = cx + cos(angles[i]) * r;
    float py = cy + sin(angles[i]) * r;
    float endX = 0;
    float endY = 0;
    
    // 0 - sho, 1 - drib, 2 - pac, 3 - pas, 4 - def
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
      default:
        break;
    }
    
    int tx = int(map(endX, 0, surfaceW, matDimension[0], matDimension[2]));
    int ty = int(map(endY, 0, surfaceH, matDimension[1], matDimension[3]));
    
    cubes[i].target(int(tx), int(ty), cubes[i].theta);
    
  }
}

void draw() {
  long now = System.currentTimeMillis();
  PVector surfaceMouse = surface.getTransformedMouse();
  
  if (mousePressed == true) {
    p++;
  }
  
  projectData();

  offscreen.beginDraw();

  // Draw the UI background
  drawBackground();
  
  // render shape from toio positions
  color c = color(255, 253, 134, 127);
  offscreen.fill(c);
  offscreen.tint(255, 100);
  offscreen.stroke(204, 201, 46);
  offscreen.strokeWeight(4);

  offscreen.beginShape();
  int firstX = 0;
  int firstY = 0;

  for (int i = 0; i < nCubes; i++) {
    cubes[i].checkActive(now);

    if (cubes[i].isActive) {

      // map mat dimensions to the dimensions of the surface being projected onto
      int pointX = int(map(cubes[i].x, matDimension[0], matDimension[2], 0, surfaceW));
      int pointY = int(map(cubes[i].y, matDimension[1], matDimension[3], 0, surfaceH));
      
      // store the first vertex we draw
      if (i == 0) {
        firstX = pointX;
        firstY = pointY;
      }

      // draw a vertex
      offscreen.vertex(pointX, pointY);
      
      // draw to the first vertex again so the shape closes
      if (i == nCubes - 1) {
        offscreen.vertex(firstX, firstY);
      }
    }
 }
  offscreen.endShape();
  offscreen.endDraw();

  background(0);
  surface.render(offscreen);
}
