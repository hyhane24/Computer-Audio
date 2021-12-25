import beads.*;
import controlP5.*;
import org.jaudiolibs.beads.*;

ControlP5 p5;

Button noFilter;
Button lowPassFilter;
Button highPassFilter;
Button micOn;
Button startEventStream;
Slider cutOffFreqSlider;

PowerSpectrum ps;
Frequency f;
Glide frequencyGlide;
WavePlayer wp;

float meanFrequency = 400.0;

color fore = color(255, 255, 255);
color back = color(0,0,0);
color highlight = color(255, 0, 0);

int setHeight = 600;

SamplePlayer player = null;
Gain g, waveGain;
boolean micToggle = false;
boolean norm = false;
UGen microphoneIn;

PeakDetector beatDetector;
float brightness;

SamplePlayer normal;
SamplePlayer alert;

Gain masterGain;
Gain musicGain;

Glide masterGainGlide;
Glide musicGainGlide;
Glide filterGlide;

BiquadFilter filter;

TextToSpeechMaker ttsMaker; 

String eventDataJSON2 = "dog_actions.json";

NotificationServer notificationServer;
ArrayList<Notification> notifications;

MyNotificationListener myNotificationListener;

void setup() {
  size(800, 750);
  p5 = new ControlP5(this);
  
  ac = new AudioContext();
  
  Bead endListener = new Bead() {
    public void messageReceived(Bead message) {
      SamplePlayer sp = (SamplePlayer) message;
      filterGlide.setValue(10.0);
      musicGainGlide.setValue(1.0);
      sp.pause(true);
    }
  };
  
  microphoneIn = ac.getAudioInput();
  
  g = new Gain(ac, 2, 0.5);
  ac.out.addInput(g);
  
  frequencyGlide = new Glide(ac, 50, 10);
  wp = new WavePlayer(ac, frequencyGlide, Buffer.SINE);
  waveGain = new Gain(ac, 1, 0);
  ac.out.addInput(waveGain);

  try {
  
    player = getSamplePlayer("live.wav",false);
    player.setLoopType(SamplePlayer.LoopType.valueOf("LOOP_FORWARDS"));
    
  }
  catch(Exception e) {
  
    e.printStackTrace();
  }
  
  normal = getSamplePlayer("normal.wav");
    normal.setEndListener(endListener);
    normal.pause(true);
    
  alert = getSamplePlayer("alert.wav");
  alert.setEndListener(endListener);
  alert.pause(true);
    
  waveGain.addInput(wp);

  filter = new BiquadFilter(ac, BiquadFilter.AP, 1000.0, 0.5f);
  filter.addInput(player);
  filter.addInput(normal);
  filter.addInput(alert);
  g.addInput(filter);  

  ShortFrameSegmenter sfs = new ShortFrameSegmenter(ac);
  sfs.addInput(filter);

  FFT fft = new FFT();
  sfs.addListener(fft);

  ps = new PowerSpectrum();
  fft.addListener(ps);

  f = new Frequency (44100.0f);
  ps.addListener(f);
  
  SpectralDifference sd = new SpectralDifference(ac.getSampleRate());
  ps.addListener(sd);
  
  beatDetector = new PeakDetector();
  sd.addListener(beatDetector);
  beatDetector.setThreshold(0.2f);
  
  beatDetector.setAlpha(.9f);
  
  beatDetector.addMessageListener(
          new Bead() {
            protected void messageReceived(Bead b) {
              brightness = 1.0;
            }
          } 
        );
  
  ac.out.addDependent(sfs);
  
  ttsMaker = new TextToSpeechMaker();
  
  String exampleSpeech = "Hello Stella be with your pet Max with Pet Mike";
 
  ttsExamplePlayback(exampleSpeech); 
  
  //START NotificationServer setup
  notificationServer = new NotificationServer();
  
  myNotificationListener = new MyNotificationListener();
  notificationServer.addListener(myNotificationListener);
    
  //END NotificationServer setup
  
  noFilter = p5.addButton("noFilter")
    .setPosition(20, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("No Filter");

  lowPassFilter = p5.addButton("lowPassFilter")
    .setPosition(120, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("Low Pass");

  highPassFilter = p5.addButton("highPassFilter")
    .setPosition(220, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("High Pass");
  
  cutOffFreqSlider = p5.addSlider("cutOffFreqSlider")
    .setPosition(20, height - 100)
    .setSize(380, 20)
    .setRange(20, 15000)
    .setValue(2000)
    .setLabel("Cutoff Frequency");

  micOn = p5.addButton("micOn")
    .setPosition(480, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("Mic Toggle");
    
   p5.addButton("playNormal")
  .setPosition(380, height-70)
  .setSize(80, 50)
  .activateBy((ControlP5.RELEASE))
  .setLabel("Normal");
  
  startEventStream = p5.addButton("startEventStream")
    .setPosition(650,height-70)
    .setSize(100,50)
    .setLabel("Start Event Stream");

  ac.start();
}

void startEventStream(int value) {
  notificationServer.loadEventStream(eventDataJSON2);
}

int time;

void draw()
{
  int strongestFreqIndex = 0;
  
  background(back);
  stroke(fore);

  if (f.getFeatures() != null && random(1.0) > 0.75) {
    float inputFrequency = f.getFeatures();
    if (inputFrequency < 3000) {
      meanFrequency = (0.4 * inputFrequency) + (0.6 * meanFrequency);
      frequencyGlide.setValue(meanFrequency);
    }
  }
  
  fill(255);
  text(" Dectected Strongest Frequency: " + meanFrequency, 400, 100);
  text(" Heart beat is one of the most accurate way of measuring anxiety.", 350, 140);
  text(" If fluctuation in heart beat is far greater than normal mode, check on your pet.", 350, 160);
  
  //text(" Low filter is optimized to check biometrics.", 520, 630);
  //text(" High filter is optimized to check vocal ques.", 520, 650);
  
  
  fill(brightness*255);
  ellipse(350, 95, 20, 20);
  
  int dt = millis() - time;
  brightness -= (dt * 0.01);
  if (brightness < 0) brightness = 0;
  time += dt;

  strongestFreqIndex = (int) ((meanFrequency / 19980.0) * 256.0);

  float[] features = ps.getFeatures();
  if(features != null)
    {
    for(int x = 0; x < width; x++)
    {
      int featureIndex = (x * features.length) / width;
      int barHeight = Math.min((int)(features[featureIndex] *
      setHeight), setHeight - 1);
      if (featureIndex == strongestFreqIndex) {
        stroke(highlight);
      }
      else {
        stroke(fore);
      }
      line(x, setHeight, x, setHeight - barHeight);
    }
  }
}

void cutOffFreqSlider(float value) {
  filter.setFrequency(value);
}

void lowPassFilter() {
  filter.setType(BiquadFilter.LP);
}
void highPassFilter() {
  filter.setType(BiquadFilter.HP);
}
void noFilter() {
  filter.setType(BiquadFilter.AP);
}

void micOn() {
  if(!micToggle){
    g.setGain(1.0f);
    micToggle = true;
    stateSwitcher();
  } else {
    g.setGain(.3f);
    micToggle = false;
    stateSwitcher();
  }
}

void playNormal(){
  if(!norm){
    player.pause(true);
    normal.start(0);
    norm = true;
    stateSwi();
  } else {
    player.pause(false);
    norm = false;
    stateSwi();
  }
}

boolean aler = false;
void alert(){
  if(aler){
    player.pause(true);
    alert.start(0);
    aler = true;
    stateS();
  } else {
    player.pause(false);
    aler = false;
    stateS();
  }
}

void stateSwitcher() {
  filter.clearInputConnections();
  
  if (micToggle) {
    filter.addInput(microphoneIn);
  } else {
    filter.addInput(player);
  }
}

void stateSwi() {
  filter.clearInputConnections();
  if (norm) {
    filter.addInput(normal);
  } else {
    filter.addInput(player);
  }
  
}

void stateS() {
  if (aler) {
    filter.addInput(player);
  } 
}

void keyPressed() {
  //example of stopping the current event stream and loading the second one
  if (key == RETURN || key == ENTER) {
    notificationServer.stopEventStream(); //always call this before loading a new stream
    notificationServer.loadEventStream(eventDataJSON2);
    println("**** New event stream loaded: " + eventDataJSON2 + " ****");
  }
    
}

//in your own custom class, you will implement the NotificationListener interface 
//(with the notificationReceived() method) to receive Notification events as they come in
class MyNotificationListener implements NotificationListener {
  
  public MyNotificationListener() {
    //setup here
  }
  
  //this method must be implemented to receive notifications
  public void notificationReceived(Notification notification) { 
    println("<Example> " + notification.getType().toString() + " notification received at " 
    + Integer.toString(notification.getTimestamp()) + " ms");
    
    String debugOutput = ">>> ";
    switch (notification.getType()) {
      case Bark:
        debugOutput += "Dog barked: ";
        String exampleSpeech = "Bark, cautious";
        ttsExamplePlayback(exampleSpeech); 
        break;
      case HeartBeat:
        debugOutput += "Irregular heart rate: ";
        break;
      case Play:
        debugOutput += "Dog played: ";
        break;
      case FoodEat:
        debugOutput += "Dog ate: ";
        break;
      case Squeal:
        debugOutput += "Dog squealed: ";
        String exampleSpee = "Danger";
        ttsExamplePlayback(exampleSpee); 
        break;
      case Sleep:
        debugOutput += "Dog slept: ";
        break;
    }
    debugOutput += notification.toString();
    //debugOutput += notification.getLocation() + ", " + notification.getTag();
    
    println(debugOutput);
    
   //You can experiment with the timing by altering the timestamp values (in ms) in the exampleData.json file
    //(located in the data directory)
  }
}

void ttsExamplePlayback(String inputSpeech) {
  //create TTS file and play it back immediately
  //the SamplePlayer will remove itself when it is finished in this case
  
  String ttsFilePath = ttsMaker.createTTSWavFile(inputSpeech);
  println("File created at " + ttsFilePath);
  
  //createTTSWavFile makes a new WAV file of name ttsX.wav, where X is a unique integer
  //it returns the path relative to the sketch's data directory to the wav file
  
  
  SamplePlayer sp = getSamplePlayer(ttsFilePath, true); 
  //true means it will delete itself when it is finished playing
  //you may or may not want this behavior!
  
  ac.out.addInput(sp);
  sp.setToLoopStart();
  sp.start();
  println("TTS: " + inputSpeech);
}
