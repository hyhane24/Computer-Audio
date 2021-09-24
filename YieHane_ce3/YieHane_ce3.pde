import controlP5.*;
import beads.*;
import org.jaudiolibs.beads.*;

//declare global variables at the top of your sketch
//AudioContext ac; is declared in helper_functions

ControlP5 p5;

SamplePlayer music;
SamplePlayer voice1;
SamplePlayer voice2;

Gain masterGain;
Gain musicGain;

Glide masterGainGlide;
Glide musicGainGlide;
Glide filterGlide;

BiquadFilter duckFilter;
float HP_CUTOFF = 5000.0;

//end global variables

//runs once when the Play button above is pressed
void setup() {
  size(320, 240); //size(width, height) must be the first line in setup()
  ac = new AudioContext(); //AudioContext ac; is declared in helper_functions 
  p5 = new ControlP5(this); 
  
  Bead endListener = new Bead() {
    public void messageReceived(Bead message) {
      SamplePlayer sp = (SamplePlayer) message;
      filterGlide.setValue(10.0);
      musicGainGlide.setValue(1.0);
      sp.pause(true);
    }
  };
  
  music = getSamplePlayer("intermission.wav");
  
  // the following files SHOULD have been played, but failed
  //please read readme.txt for detailed explanations 
  //voice1 = getSamplePlayer("voice_1.wav");
  //voice2 = getSamplePlayer("voice_2.wav");
  
  // these are dummy .wav files that do work, but are not my recordings
  voice1 = getSamplePlayer("pho.wav");
  voice2 = getSamplePlayer("pho.wav");
  
  //another version of voice files, but still did not work 
  //voice1 = getSamplePlayer("voiceOne.wav");
  //voice2 = getSamplePlayer("voiceTwo.wav");
  
  voice1.setEndListener(endListener);
  voice2.setEndListener(endListener);
  
  music.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  
  voice1.pause(true);
  voice2.pause(true);
  
  musicGainGlide = new Glide(ac, 1.0, 500);
  musicGain = new Gain(ac, 1, musicGainGlide);
  masterGainGlide = new Glide (ac, 1.0, 500);
  masterGain = new Gain(ac, 1, masterGainGlide);
  
  filterGlide = new Glide(ac, 10.0, 500);
  duckFilter = new BiquadFilter(ac, BiquadFilter.HP, filterGlide, 0.5);
  
  duckFilter.addInput(music);
  
  musicGain.addInput(duckFilter);
  masterGain.addInput(musicGain);
  masterGain.addInput(voice1);
  masterGain.addInput(voice2);
  
  ac.out.addInput(masterGain);
  
  p5.addSlider("GainSlider")
  .setPosition(20, 20)
  .setSize(20, 200)
  .setValue(50.0)
  .setLabel("Volume");
  
  p5.addButton("PlayVoice1")
  .setPosition(150, 90)
  .setSize(70, 30)
  .setLabel("Voice 1");
             
  p5.addButton("PlayVoice2")
  .setPosition(150, 140)
  .setSize(70, 30)
  .setLabel("Voice 2");
  
  ac.start();
}

void PlayVoice1(){
  voice2.pause(true);
  filterGlide.setValue(HP_CUTOFF);
  musicGainGlide.setValue(1.0);
  voice1.setToLoopStart();
  voice1.start();
}

void PlayVoice2() {
  voice1.pause(true);
  filterGlide.setValue(HP_CUTOFF);
  musicGainGlide.setValue(1.0);
  voice2.setToLoopStart();
  voice2.start();
}

void GainSlider(int value){
  masterGainGlide.setValue(value/10);
}

void draw() {
  background(0);  //fills the canvas with black (0) each frame
}
