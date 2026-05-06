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

  bg = loadImage("bg.png");
}

void drawBackground() {
  offscreen.background(255, 199, 226); // pink background

  float cx = surfaceW / 2 - 105;   // move left
  float cy = 75;                 // move up

  float r = 45;
  float circleSize = 90;

  // Main white circle
  offscreen.fill(255);
  offscreen.noStroke();
  offscreen.ellipse(cx, cy, circleSize, circleSize);

  // Grey stat lines
  offscreen.stroke(190);
  offscreen.strokeWeight(2);

  offscreen.line(cx, cy, cx, cy - r);           // Shooting
  offscreen.line(cx, cy, cx + 43, cy - 14);     // Dribbling
  offscreen.line(cx, cy, cx + 27, cy + 37);     // Pace
  offscreen.line(cx, cy, cx - 27, cy + 37);     // Passing
  offscreen.line(cx, cy, cx - 43, cy - 14);     // Defending

  // Center point
  offscreen.fill(0);
  offscreen.noStroke();
  offscreen.ellipse(cx, cy, 6, 6);

  // Labels
  offscreen.fill(0);
  offscreen.noStroke();
  offscreen.textAlign(CENTER, CENTER);
  offscreen.textFont(regularFont);
  offscreen.textSize(7);

  offscreen.text("Shooting", cx, cy - 58);
  offscreen.text("Dribbling", cx + 67, cy - 14);
  offscreen.text("Pace", cx + 38, cy + 48);
  offscreen.text("Passing", cx - 47, cy + 48);
  offscreen.text("Defending", cx - 67, cy - 14);

  // Instruction text
  offscreen.textFont(boldFont);
  offscreen.textSize(8);
  offscreen.text("Select your player to view data:", cx, 225);

  // Buttons
  offscreen.textSize(8);
  offscreen.text("MENU", 75, 267);
  offscreen.text("SELECT", 295, 267);

  offscreen.noFill();
  offscreen.strokeWeight(2);

  // Menu circle
  offscreen.stroke(255, 204, 0);
  offscreen.ellipse(75, 295, 30, 30);

  // Select circle
  offscreen.stroke(0, 140, 60);
  offscreen.ellipse(295, 295, 30, 30);

  // Center rotate button
  offscreen.fill(255);
  offscreen.noStroke();
  offscreen.ellipse(cx, 295, 45, 45);

  // Rotate symbol
  offscreen.fill(0);
  offscreen.textFont(regularFont);
  offscreen.textSize(24);
  offscreen.text("↻", cx, 292);

  // Bottom instruction
  offscreen.textFont(boldFont);
  offscreen.textSize(7);
  offscreen.text("Rotate Toio to Change Player", cx, 338);

  offscreen.textFont(regularFont);
}


void draw() {
  long now = System.currentTimeMillis();
  PVector surfaceMouse = surface.getTransformedMouse();

  offscreen.beginDraw();

  // Draw the UI background
  drawBackground();

  // Optional mouse test circle
  // offscreen.fill(0, 255, 0);
  // offscreen.noStroke();
  // offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);

  // Render shape from toio positions
  color c = color(255, 253, 134, 127);
  offscreen.fill(c);
  offscreen.tint(255, 100);
  offscreen.stroke(204, 201, 46);
  offscreen.strokeWeight(4);

  offscreen.beginShape();

  for (int i = 0; i < nCubes; i++) {
    cubes[i].checkActive(now);

    if (cubes[i].isActive) {
      // map mat dimensions to the dimensions of the surface being projected onto
      int pointX = int(map(cubes[i].x, matDimension[0], matDimension[2], 0, surfaceW));
      int pointY = int(map(cubes[i].y, matDimension[1], matDimension[3], 0, surfaceH));

      // draw a vertex
      offscreen.vertex(pointX, pointY);
    }
x  }

  offscreen.endShape();
  offscreen.endDraw();

  background(0);
  surface.render(offscreen);
}
