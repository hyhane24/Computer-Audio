import controlP5.*;
import beads.*;
import org.jaudiolibs.beads.*;

//declare global variables at the top of your sketch
ControlP5 p5;
SamplePlayer music;
// store the length, in ms, of the music SamplePlayer
double musicLength;
// endListener to detect beginning/end of music playback, rewind, FF
Bead musicEndListener;

Glide filterGlide;
Glide musicRateGlide;

SamplePlayer play;
SamplePlayer stop;
SamplePlayer fastForward;
SamplePlayer rewind;
SamplePlayer reset;

//end global variables

//runs 
void setup() {
  size(210, 220); //size(width, height) must be the first line in setup()
  ac = new AudioContext(); //AudioContext ac; is declared in helper_functions 
  p5 = new ControlP5(this);
         
  music = getSamplePlayer("theme.wav");

  // get the length of the music sample to use in tape deck function button callbacks
  musicLength = music.getSample().getLength();
  
  play = getSamplePlayer("play.wav");
  play.pause(true);
  stop = getSamplePlayer("stop.wav");
  stop.pause(true);
  reset = getSamplePlayer("genClick.wav");
  reset.pause(true);
  fastForward = getSamplePlayer("genClick.wav");
  fastForward.pause(true);
  rewind = getSamplePlayer("genClick.wav");
  rewind.pause(true);

  // create music playback rate Glide, set to 0 initially or music will play on startup
  musicRateGlide = new Glide(ac, 0, 500);
  // use rateGlide to control music playback rate
  // notice that music.pause(true) is not needed since
  // we set the initial playback rate to 0
  music.setRate(musicRateGlide);

  // create all of your button sound effect SamplePlayers
  // and connect them into a UGen graph to ac.out
  
  ac.out.addInput(music);
  ac.out.addInput(play);
  ac.out.addInput(stop);
  ac.out.addInput(reset);
  ac.out.addInput(fastForward);
  ac.out.addInput(rewind);

  // create a reusable endListener Bead to detect end/beginning of music playback
  musicEndListener = new Bead()
  {
    public void messageReceived(Bead message)
    {
      // Get handle to the SamplePlayer which received this endListener message
      SamplePlayer sp = (SamplePlayer) message;

      // remove this endListener to prevent its firing over and over
      // due to playback position bugs in Beads
      sp.setEndListener(null);
      
      // The playback head has reached either the end or beginning of the tape.
      // Stop playing music by setting the playback rate to 0 immediately
      setPlaybackRate(0, true);
      
      stop.start(0);
    }
  };
  
  p5.addButton("Play")
    .setPosition(width/3, 10)
    .setSize(width/3, 20)
    .activateBy((ControlP5.RELEASE));
    
  p5.addButton("Rewind")
    .setPosition(width/3, 50)
    .setSize(width/3, 20)
    .activateBy((ControlP5.RELEASE));
    
  p5.addButton("FastForward")
    .setCaptionLabel("Fast Forward")
    .setPosition(width/3, 90)
    .setSize(width/3, 20)
    .activateBy((ControlP5.RELEASE));
    
  p5.addButton("Stop")
    .setPosition(width/3, 130)
    .setSize(width/3, 20)
    .activateBy((ControlP5.RELEASE));
    
  p5.addButton("Reset")
    .setPosition(width/3, 170)
    .setSize(width/3, 20)
    .activateBy((ControlP5.RELEASE));

  // Create the UI
  ac.start();
}

public boolean IsAtEndOfTape() {
  return (music.getPosition() >= musicLength);
}

public boolean IsAtStartOfTape() {
  return (music.getPosition() <= 0);
}

// Add endListener to the music SamplePlayer if one doesn't already exist
public void addEndListener() {
  if (music.getEndListener() == null) {
    music.setEndListener(musicEndListener);
  }
}

// Set music playback rate using a Glide
public void setPlaybackRate(float rate, boolean immediately) {
  // Make sure playback head position isn't past end or beginning of the sample 
  if (music.getPosition() >= musicLength) {
    println("End of tape");
    // reset playback head position to end of sample (tape)
    music.setToEnd();
  }

  if (music.getPosition() < 0) {
    println("Beggining of tape");
    // reset playback head position to beginning of sample (tape)
    music.reset();
  }
  
  if (immediately) {
    musicRateGlide.setValueImmediately(rate);
  }
  else {
    musicRateGlide.setValue(rate);
  }
}

// Assuming you have a ControlP5 button called ‘Play’
public void Play()
{
  // if playback head isn't at the end of tape, set rate to 1
  if (music.getPosition() < musicLength) {
    setPlaybackRate(1, false);
    addEndListener();
  }
  
  // always play the button sound
  play.start(0);
}

// Create similar button handlers for fast-forward, rewind, stop and reset

public void FastForward() {
  if (music.getPosition() < musicLength) {
    setPlaybackRate(5, false);
    addEndListener();
  }
  fastForward.start(0);
}

public void Stop() {
  stop.start(0);
  setPlaybackRate(0, false);
}

public void Reset(){
  reset.start(0);
  
  music.reset();
  setPlaybackRate(0, true);
}

public void Rewind() {
  if (music.getPosition() > 0) {
    setPlaybackRate(-5, false);
    addEndListener();
  }
  rewind.start(0);
}


void draw() {
  background(0);  //fills the canvas with black (0) each frame
  
}
