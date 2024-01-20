import java.util.*;
import java.util.stream.*;

State curState;

abstract class State{
   public abstract void draw();
   public abstract void setup();
   public abstract void mousePressed(float x, float y);
}

public void changeState(State next){
   next.setup(); 
   curState = next;
}

class Button{
   float x, y, w, h;
   String txt;
   public Button(float x, float y, float w, float h, String text){
      this.x = x;
      this.y = y;
      this.w = w;
      this.h = h;
      this.txt = text;
   }
   
   public void render(){
      fill(200, 200, 200);
      stroke(0, 0, 0);
      rect(x, y, w, h);
      textAlign(CENTER, CENTER);
      strokeWeight(4);
      fill(0, 0, 0);
      stroke(0, 0, 0);
      textSize(20);
      text(txt, x, y, w, h);
   }
   
   public boolean clicked(float mx, float my){
      return x <= mx && mx <= x + w && y <= my && my <= y + h;
   }
}

public class ChooseState extends State{
   Button quad, sine;
  
   public void setup(){
     float bx = width / 4;
     float bw = width / 2;
     float by = 350;
     float bh = 40;
     quad = new Button(bx, by, bw, bh, "Quadratic Least Fit");
     by += bh + 10;
     sine = new Button(bx, by, bw, bh, "Sine Least Fit");
   }
   
   public void draw(){
     background(220, 255, 183);
     fill(255, 104, 104);
     textAlign(CENTER, TOP);
     textSize(70);
     text("Gradient Descent Experiments", width/2, 50);
     textSize(20);
     fill(0, 0, 0);
     text("By Shane and Daniel", width/2, 150);
     
     quad.render();
     sine.render();
   }
   
   public void mousePressed(float x, float y){
     if(quad.clicked(x, y)) changeState(new QuadraticFitState());
     if(sine.clicked(x, y)) changeState(new SineFitState());
   }
}

void setup(){
  size(1200, 800);
  curState = new ChooseState();
  curState.setup();
}

void draw(){
   curState.draw(); 
}

void mousePressed(){
   curState.mousePressed(mouseX, mouseY); 
}
