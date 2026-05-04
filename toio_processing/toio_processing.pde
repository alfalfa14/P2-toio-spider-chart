import oscP5.*;
import netP5.*;
import deadpixel.keystone.*;
Keystone ks;
CornerPinSurface surface;
PGraphics offscreen;
int surfaceW = 820;
int surfaceH = 410;

//constants
//The soft limit on how many toios a laptop can handle is in the 10-12 range
//the more toios you connect to, the more difficult it becomes to sustain the connection
int nCubes = 5;
int cubesPerHost = 12;
int maxMotorSpeed = 115;
int xOffset;
int yOffset;

//// Instruction for Windows Users  (Feb 2. 2025) ////
// 1. Enable WindowsMode and set nCubes to the exact number of toio you are connecting.
// 2. Run Processing Code FIRST, Then Run the Rust Code. After running the Rust Code, you should place the toio on the toio mat, then Processing should start showing the toio position.
// 3. When you re-run the processing code, make sure to stop the rust code and toios to be disconnected (switch to Bluetooth stand-by mode [blue LED blinking]). If toios are taking time to disconnect, you can optionally turn off the toio and turn back on using the power button.
// Optional: If the toio behavior is werid consider dropping the framerate (e.g. change from 30 to 10)
// 
boolean WindowsMode = false; //When you enable this, it will check for connection with toio via Rust first, before starting void loop()

int framerate = 30;

int[] matDimension = {45, 45, 455, 455};

//for OSC
OscP5 oscP5;
//where to send the commands to
NetAddress[] server;

//we'll keep the cubes here
Cube[] cubes;
// array of PVectors to track vertex positions (toio 0-4 positions)
PVector[] vertices;

void settings() {
  fullScreen(P3D);
}

void setup() {
  //launch OSC server
  oscP5 = new OscP5(this, 3333);
  server = new NetAddress[1];
  server[0] = new NetAddress("127.0.0.1", 3334);

  // create PVector array
  vertices = new PVector[nCubes];
  //create cubes
  cubes = new Cube[nCubes];
  for (int i = 0; i< nCubes; ++i) {
    cubes[i] = new Cube(i);
  }

  xOffset = matDimension[0] - 45;
  yOffset = matDimension[1] - 45;

  //do not send TOO MANY PACKETS
  //we'll be updating the cubes every frame, so don't try to go too high
  frameRate(framerate);
  if(WindowsMode){
  check_connection();
  }

  
  // keystone projection
  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(surfaceW, surfaceH, 20);
  offscreen = createGraphics(surfaceW, surfaceH, P3D);
}


void draw() {
  long now = System.currentTimeMillis();
  PVector surfaceMouse = surface.getTransformedMouse();
  
  offscreen.beginDraw();
  offscreen.background(255);
  offscreen.fill(0, 255, 0);
  offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
  offscreen.endDraw();
  background(0);
  
  // initial loop to get toio positions
  for (int i = 0; i < nCubes; i++) {
    cubes[i].checkActive(now);
    
    if (cubes[i].isActive) {
      vertices[i] = new PVector(cubes[i].x, cubes[i].y);
    }
  }
  
  // subsequent loop to render shape from toio positions
  for (int i = 0; i < nCubes; i++) {
    cubes[i].checkActive(now);
    
    if (i == 0) {
     offscreen.beginShape();
    }
    
    if (cubes[i].isActive) {
      vertex(vertices[i].x, vertices[i].y);
    }
    
    if (i == nCubes - 1) {
      offscreen.endShape();
    }
  }
  surface.render(offscreen);
  
  
  
}
