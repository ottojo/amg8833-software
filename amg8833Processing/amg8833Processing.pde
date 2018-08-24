import hypermedia.net.*;

float[][] image = new float[8][8];
float[][] interpolated = new float[16][16];
UDP udp;

void setup()
{
  size(512, 512);
  frameRate(20);
  udp= new UDP(this, 1339, "10.0.2.1");
  udp.listen(true);
}

void draw()
{
  // Render
 /* for (int x = 0; x < 16; x++) {
    for (int y = 0; y < 16; y++) {
      fill(Math.round(255*Math.sqrt(interpolated[x][y])), Math.round(255*Math.pow(interpolated[x][y], 3)), Math.round(255*(Math.sin(2 * Math.PI * interpolated[x][y])>=0 ? Math.sin(2 * Math.PI * interpolated[x][y]) : 0 )));
      rect(32*x, 32*y, 32, 32);
    }
  }*/
  for (int x = 0; x < 8; x++) {
    for (int y = 0; y < 8; y++) {
      fill(Math.round(255*Math.sqrt(image[x][y])), Math.round(255*Math.pow(image[x][y], 3)), Math.round(255*(Math.sin(2 * Math.PI * image[x][y])>=0 ? Math.sin(2 * Math.PI * image[x][y]) : 0 )));
      rect(32*2*x, 32*2*y, 32*2, 32*2);
    }
  }
}


void receive(byte[] data, String HOST_IP, int PORT_RX) {
  println("received");
  String rec = trim(new String(data));
  if (rec == null)
    return;
  String[] list = split(rec, ',');
  if (list.length < 64 || !list[0].equals("d"))
    return;
  int i = 1;
  for (int y = 7; y >= 0; y--) {
    for (int x = 7; x >= 0; x--) {
      image[x][y]=Integer.parseInt(trim(list[i]));
      i++;
    }
  }
  // Scale
  float max = image[0][0];
  float min = image[0][0];
  for (int x = 0; x<8; x++) {
    for (int y = 0; y<8; y++) {
      if (image[x][y] > max)
        max = image[x][y];
      if (image[x][y] < min)
        min = image[x][y];
    }
  }

  println("max "+max);
  println("min "+min);
   max = 120;
   min = 75;
  float scalefactor = 1 / (float) (max-min);
  for (int x = 0; x<8; x++) {
    for (int y = 0; y<8; y++) {
      image[x][y] -= min;
      image[x][y] *= scalefactor;
    }
  }

  // Interpolate
  for (int x = 1; x < 7; x++) {
    for (int y = 1; y < 7; y++) {
      //Left side
      //ax+b
      {
        Polynom mid = new Polynom(image[x][y]-image[x-1][y], image[x-1][y]);

        Polynom top = new Polynom(image[x][y-1]-image[x-1][y-1], image[x-1][y-1]);

        Polynom bot = new Polynom(image[x][y+1]-image[x-1][y+1], image[x-1][y+1]);

        //Top Left
        interpolated[2*x][2*y] = new Polynom(mid.at(3f/4f)-top.at(3f/4f), top.at(3f/4f)).at(3f/4f);
        //Bottom left
        interpolated[2*x][2*y+1] = new Polynom(bot.at(3f/4f)-mid.at(3f/4f), mid.at(3f/4f)).at(1f/4f);
      }

      {
        Polynom mid = new Polynom(image[x+1][y]-image[x][y], image[x][y]);

        Polynom top = new Polynom(image[x+1][y-1]-image[x][y-1], image[x][y-1]);

        Polynom bot = new Polynom(image[x+1][y+1]-image[x][y+1], image[x][y+1]);

        //Top Left
        interpolated[2*x+1][2*y] = new Polynom(mid.at(1f/4f)-top.at(1f/4f), top.at(1f/4f)).at(3f/4f);
        //Bottom left
        interpolated[2*x+1][2*y+1] = new Polynom(bot.at(1f/4f)-mid.at(1f/4f), mid.at(1f/4f)).at(1f/4f);
      }
    }
  }
}

class Polynom {
  float a;
  float b;
  public float at(float x) {
    return a * x + b;
  }
  public Polynom(float factor, float offset) {
    a = factor;
    b= offset;
  }
}
