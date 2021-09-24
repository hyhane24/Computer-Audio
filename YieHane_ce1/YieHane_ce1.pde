import controlP5.*;
import beads.*;
import org.jaudiolibs.beads.*;

//declare global variables at the top of your sketch
//AudioContext ac; is declared in helper_functions
SamplePlayer button;
ControlP5 p5;

Gain gain;
Glide glide;

Glide cut;
BiquadFilter lp;

//end global variables

//runs once when the Play button above is pressed
void setup() {
  size(320, 240); //size(width, height) must be the first line in setup()
  ac = new AudioContext(); //AudioContext ac; is declared in helper_functions 
  p5 = new ControlP5(this); 
  
  button = getSamplePlayer("pho.wav");
  button.pause(true);
  
  glide = new Glide(ac, 1.0, 500);
  gain = new Gain(ac, 1, glide);
  
  // tested constructors to see what works best 
  cut = new Glide(ac, 1000.0, 1);
  
  lp = new BiquadFilter(ac, BiquadFilter.LP, cut, 0.5f);
  
  lp.addInput(button);
  
  gain.addInput(lp);
  
  ac.out.addInput(gain);
  
  p5.addButton("Play")
  .setPosition(200, 100)
  .setSize(80, 40)
  .setLabel("Play Music");
             
  p5.addSlider("GainSlider")
  .setPosition(40, 20)
  .setSize(30, 200)
  .setRange(0,100)
  .setValue(50)
  .setLabel("Gain");
  
  p5.addSlider("FilterSlider")
  .setPosition(120,20)
  .setSize(30, 200)
  .setRange(0, 100)
  .setValue(100)
  //.setNumberOfTickMarks(20)
  //.setBroadcast(true)
  .setLabel("LP Filter");
  
  ac.start();
}

void Play(){
  button.pause(false);
  button.reset();
}

void GainSlider(int i){
  glide.setValue(i/10);
}

void FilterSlider(int j) {
  cut.setValue(j*100);
  //lp.setFrequency(j*100);
}


void draw() {
  background(0);  //fills the canvas with black (0) each frame
  
}
