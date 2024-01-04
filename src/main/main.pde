import java.util.*;
import java.util.stream.*;
Variable[] vars = new Variable[]{new Variable(5, false, "slope"), new Variable(5, false, "bias")};
List<Float> xCoord=new ArrayList<Float>(Arrays.asList(0.0f)), yCoord=new ArrayList<Float>(Arrays.asList(0.0f));
Model model;

void setup(){  
  setModel();
  size(400, 400);
}

void setModel(){
  Variable[] x = new Variable[xCoord.size()];
  Variable[] y = new Variable[yCoord.size()];
  for(int i = 0; i < x.length; i++){
    x[i] = new Variable(xCoord.get(i), true, "x" + i);
    y[i] = new Variable(yCoord.get(i), true, "y" + i);
  }
  Variable negativeOne = new Variable(-1, true, "-1");
  Variable div = new Variable(1.0f/xCoord.size(), true, "1/" + xCoord.size());
  
  Trans[] ax = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) ax[i] = new Product(x[i], vars[0]);
  Trans[] plusB = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) plusB[i] = new Sum(new Trans[]{ax[i], vars[1]});
  Trans[] residual = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) residual[i] = new Sum(new Trans[]{plusB[i], new Product(y[i], negativeOne)});
  Trans[] squaredResidual = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) squaredResidual[i] = new Exponent(residual[i], 2);
  Trans totResidual = new Sum(squaredResidual);
  Loss loss = new Loss(new Product(totResidual, div));
  
  List<Variable> allInputs = new ArrayList<Variable>(Arrays.asList(x));
  for(Variable i : y) allInputs.add(i);
  allInputs.add(negativeOne);
  allInputs.add(div);
  for(Variable i : vars) allInputs.add(i);
  model = new Model(allInputs, Arrays.asList(plusB), loss); 
}

void draw(){
  background(255);
  pushMatrix();
  translate(50, 350);
  scale(1, -1);
  strokeWeight(3);
  stroke(0, 0, 0);
  
  line(0, -400, 0, 400);
  line(0, 0, 400, 0);
  
  scale(20, 20);
  strokeWeight(0.4);
  stroke(0, 0, 255);
  for(int i = 0; i < xCoord.size(); i++){
     point(xCoord.get(i), yCoord.get(i)); 
  }
  
  strokeWeight(0.1);
  stroke(255, 0, 0);
  line(0, vars[1].getVal(), 20, vars[0].getVal() * 20 + vars[1].getVal());
  popMatrix();
  
  updateVars();
}

float rho = 0.6;
float avg = 1;
void updateVars(){
  float[] divs = new float[vars.length];
  model.runModel();
  
  for(int i = 0; i < vars.length; i++) divs[i] = vars[i].getDerivative();
  float mag = 0;
  for(int i = 0; i < vars.length; i++) mag += (float) Math.pow(divs[i], 2);
  mag = (float) Math.sqrt(mag);
  avg = avg * rho + mag * (1 - rho);
  for(int i = 0; i < vars.length; i++) divs[i] = divs[i] / avg;
  
  // TODO use either avg or mag, it's fine
  for(int i = 0; i < vars.length; i++) {
     vars[i].setVal(vars[i].getVal() - divs[i] * (float) (Math.pow(mag, 1) * 0.005)); 
  }
}

void mousePressed(){
  float x = (float) (mouseX-50) / 20;
  float y = (float) (350-mouseY) / 20;
  xCoord.add(x);
  yCoord.add(y);
  vars = new Variable[]{new Variable(vars[0].getVal(), false, "slope"), new Variable(vars[1].getVal(), false, "bias")};
  setModel();
}
