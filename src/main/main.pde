import java.util.*;
import java.util.stream.*;

State curState;

abstract class State{
   public abstract void draw();
   public abstract void setup();
   public abstract void mousePressed(float x, float y);
}

void setup(){
  size(1200, 800);
  curState = new SineFitState();
  curState.setup();
}

void draw(){
   curState.draw(); 
}

void mousePressed(){
   curState.mousePressed(mouseX, mouseY); 
}
