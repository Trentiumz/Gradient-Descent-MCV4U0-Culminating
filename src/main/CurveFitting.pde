import java.util.*;
import java.util.stream.*;

abstract class CurveFitState extends State{
  ArrayList<Float> x, y;
  float ox, oy, sx, sy;

  public CurveFitState() {
    x = new ArrayList<Float>();
    y = new ArrayList<Float>();
    x.add(0.0f);
    y.add(0.0f);
    
    this.ox = 15;
    this.oy = height / 2;
    sx = width / 2;
    sy = height / 4;
  }

  public void setup(){
    updatePoints(x, y);
  }
  public abstract void tick();
  public abstract PVector[] getCurve();
  public abstract void updatePoints(ArrayList<Float> x, ArrayList<Float> y);

  public void draw() {
    background(255);
    this.tick();
    
    pushMatrix();
    translate(ox, oy);
    scale(1, -1);
    
    strokeWeight(3);
    stroke(0, 0, 0);
    line(-ox, 0, width-ox, 0);
    line(0, -height/2, 0, height/2);
    
    strokeWeight(10);
    stroke(0, 0, 255);
    for(int i = 0; i < x.size(); i++){
       point(x.get(i) * sx, y.get(i) * sy); 
    }
    
    strokeWeight(3);
    stroke(255, 0, 0);
    PVector[] pts = getCurve();
    for(int i = 0; i < pts.length - 1; i++){
       line(pts[i].x * sx, pts[i].y * sy, pts[i+1].x * sx, pts[i+1].y * sy); 
    }
    
    popMatrix();
  }

  public void mousePressed(float x, float y) {
    this.x.add((x-ox) / sx);
    this.y.add((oy-y) / sy);
    
    this.updatePoints(this.x, this.y);
  }
}

class QuadraticFitState extends CurveFitState {
  
  Variable[] vars;
  Optimizer optimizer;
  Model model;
  
  public QuadraticFitState(){
     this.vars = new Variable[]{new Variable(0, false, "a"), new Variable(0, false, "b"), new Variable(0, false, "c")};
  }
  
  public void tick(){
     model.runModel();
     optimizer.optimize();
  }
  
  public PVector[] getCurve(){
      ArrayList<PVector> vecs = new ArrayList<PVector>();
      for(float x = -1; x <= 10; x += 0.03){
        vecs.add(new PVector(x, vars[0].getVal() * x * x + vars[1].getVal() * x + vars[2].getVal()));
      }
      PVector[] ret = new PVector[vecs.size()];
      vecs.toArray(ret);
      return ret;
  }
  
  public void updatePoints(ArrayList<Float> x, ArrayList<Float> y) {
    Variable[] xv = new Variable[x.size()];
    Variable[] yv = new Variable[y.size()];
    for (int i = 0; i < xv.length; i++) {
      xv[i] = new Variable(x.get(i), true, "x" + i);
      yv[i] = new Variable(y.get(i), true, "y" + i);
    }
    for (int i = 0; i < vars.length; i++) {
      vars[i] = new Variable(0, false, vars[i].getName());
    }

    Variable negativeOne = new Variable(-1, true, "-1");
    Variable div = new Variable(1.0f/xv.length, true, "1/" + xv.length);

    Trans[] preds = new Trans[xv.length];
    for (int i = 0; i < xv.length; i++) {
      Trans at = new Product(new Exponent(xv[i], 2), vars[0]);
      Trans bt = new Product(xv[i], vars[1]);
      preds[i] = new Sum(new Trans[]{at, bt, vars[2]});
    }
    Trans[] residual = new Trans[xv.length];
    for (int i = 0; i < xv.length; i++) residual[i] = new Sum(new Trans[]{preds[i], new Product(yv[i], negativeOne)});
    Trans[] squaredResidual = new Trans[xv.length];
    for (int i = 0; i < xv.length; i++) squaredResidual[i] = new Exponent(residual[i], 2);
    Trans totResidual = new Sum(squaredResidual);
    Loss loss = new Loss(new Product(totResidual, div));

    List<Variable> allInputs = new ArrayList<Variable>(Arrays.asList(xv));
    for (Variable i : yv) allInputs.add(i);
    allInputs.add(negativeOne);
    allInputs.add(div);
    for (Variable i : vars) allInputs.add(i);

    this.model = new Model(allInputs, Arrays.asList(preds), loss);
    this.optimizer = new Momentum(vars, (float) 0.9); 
  }
}

class SineFitState extends CurveFitState{
   Variable[] vars;
   Optimizer optimizer;
   Model model;
   
   public SineFitState(){
      this.vars = new Variable[]{new Variable(1, false, "A"), new Variable(5, false, "a"), new Variable(0, false, "b"), new Variable(0, false, "c")};
   }
 
   public void tick(){
       model.runModel();
       optimizer.optimize();
   }
   
    public PVector[] getCurve(){
        ArrayList<PVector> vecs = new ArrayList<PVector>();
        for(float x = -1; x <= 10; x += 0.03){
          vecs.add(new PVector(x, vars[0].getVal() * (float) Math.sin(vars[1].getVal() * (x + vars[2].getVal())) + vars[3].getVal()));
        }
        PVector[] ret = new PVector[vecs.size()];
        vecs.toArray(ret);
        return ret;
    }
    
    public void updatePoints(ArrayList<Float> x, ArrayList<Float> y) {
      Variable[] xv = new Variable[x.size()];
      Variable[] yv = new Variable[y.size()];
      for (int i = 0; i < xv.length; i++) {
        xv[i] = new Variable(x.get(i), true, "x" + i);
        yv[i] = new Variable(y.get(i), true, "y" + i);
      }
      this.vars = new Variable[]{new Variable(1, false, "A"), new Variable(5, false, "a"), new Variable(0, false, "b"), new Variable(0, false, "c")};
  
      Variable negativeOne = new Variable(-1, true, "-1");
      Variable div = new Variable(1.0f/xv.length, true, "1/" + xv.length);
  
      Trans[] preds = new Trans[xv.length];
      for (int i = 0; i < xv.length; i++) {
        Trans arg = new Product(vars[1], new Sum(new Trans[]{xv[i], vars[2]}));
        Trans val = new Sine(arg);
        preds[i] = new Sum(new Trans[]{new Product(vars[0], val), vars[3]});
      }
      Trans[] residual = new Trans[xv.length];
      for (int i = 0; i < xv.length; i++) residual[i] = new Sum(new Trans[]{preds[i], new Product(yv[i], negativeOne)});
      Trans[] squaredResidual = new Trans[xv.length];
      for (int i = 0; i < xv.length; i++) squaredResidual[i] = new Exponent(residual[i], 2);
      Trans totResidual = new Sum(squaredResidual);
      Loss loss = new Loss(new Product(totResidual, div));
  
      List<Variable> allInputs = new ArrayList<Variable>(Arrays.asList(xv));
      for (Variable i : yv) allInputs.add(i);
      allInputs.add(negativeOne);
      allInputs.add(div);
      for (Variable i : vars) allInputs.add(i);
  
      this.model = new Model(allInputs, Arrays.asList(preds), loss);
      this.optimizer = new Momentum(vars, (float) 0.9); 
    }
}
