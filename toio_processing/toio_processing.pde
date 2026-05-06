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
}

void drawBackground() {
  offscreen.background(255, 199, 226); // pink background
  
  // circle center positioning
  float cx = surfaceW / 2;
  float cy = 200;

  float circleSize = 300;
  float r = circleSize/2;

  // main white circle
  offscreen.fill(255);
  offscreen.noStroke();
  offscreen.ellipse(cx, cy, circleSize, circleSize);

  // stat lines
  offscreen.stroke(190);
  offscreen.strokeWeight(3);

  // angles for 5 stats (in radians)
  float[] angles = {
    radians(-90),   // Shooting (top)
    radians(-18),   // Dribbling
    radians(54),    // Pace
    radians(126),   // Passing
    radians(198)    // Defending
  };

  for (int i = 0; i < angles.length; i++) {
    float x2 = cx + cos(angles[i]) * r;
    float y2 = cy + sin(angles[i]) * r;

    offscreen.line(cx, cy, x2, y2);
  }

  offscreen.fill(0);
  offscreen.noStroke();
  offscreen.textAlign(CENTER, CENTER);
  offscreen.textFont(regularFont);
  offscreen.textSize(7);

  String[] labels = {
    "Shooting",
    "Dribbling",
    "Pace",
    "Passing",
    "Defending"
  };

  // distance slightly larger than radius so text sits outside circle
  float labelRadius = r + 20;

  for (int i = 0; i < angles.length; i++) {
    float tx = cx + cos(angles[i]) * labelRadius;
    float ty = cy + sin(angles[i]) * labelRadius;

    offscreen.text(labels[i], tx, ty);
  }
}

void draw() {
  long now = System.currentTimeMillis();
  PVector surfaceMouse = surface.getTransformedMouse();

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

      if (i == 0) {
        firstX = pointX;
        firstY = pointY;
      }

      // draw a vertex
      offscreen.vertex(pointX, pointY);

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
