import java.util.*;

/**
* A transformation takes in some number of inputs and returns one output
*/
abstract class Trans {
    private final Trans[] prev; // previous operations
    private List<Trans> nex; // next operations
    
    private float result; // result from a forward run
    private float derivative;
    
    private boolean forwardRun = false; // debugging, just to make sure everything's working properly ;)
    private boolean backwardRun = false;
    public String name = null;
    
    protected Trans(Trans[] prev){
      this.prev = prev;
      for(Trans i : prev){
        i.nex.add(this);
      }
      this.nex = new ArrayList<>();
      
      this.result = 0;
      this.derivative = 0;
    }
    
    protected Trans(Trans[] prev, String name){
      this(prev);
      this.name = name;
    }
    
    // now result is updated with what happens when this model is run
    protected abstract float runCalcs();
    public void forward() throws IllegalStateException{
      for(Trans i : prev){
        if(!i.forwardRun) throw new IllegalStateException("The previous layers must be have a forward result first!");
      }
      this.result = runCalcs();
      forwardRun = true;
    }
    
    // call updateDerivative() of nex first, now update derivatives of the transformations before it
    abstract void updateDerivatives();
    public void backward() throws IllegalStateException{
        for(Trans i : nex){
           if(!i.backwardRun || !i.forwardRun) throw new IllegalStateException("The next layers must have a backward & forward result first!");
        }
        updateDerivatives();
        backwardRun = true;
    }
    
    // -------------- UTILITY METHODS
    // get methods
    public float getResult() throws IllegalStateException{
      if(!forwardRun) throw new IllegalStateException("There isn't a result yet...");
       return result; 
    }
    public List<Trans> nextLayers(){
      return nex;
    }
    public float getDerivative(){
       return this.derivative; 
    }
    public String getName(){
      return this.name;
    }
    
    // set methods
    public void reset(){
       this.forwardRun = false;
       this.backwardRun = false;
       this.derivative = 0;
    }
    public void addVars(Set<Variable> vars){
       
    }
    public void incDerivative(float by){
       this.derivative += by; 
    }
    public String toString(){
       if(name != null) return name;
       return super.toString();
    }
}

class Variable extends Trans {
   private float val;
   boolean constant;
   public Variable(float val, boolean constant, String name){
      super(new Trans[]{}, name);
      this.val = val;
      this.constant = constant;
   }
   public Variable(float val, boolean constant){
      this(val, constant, null);
   }
   protected float runCalcs(){
      return val;
   }
   public float getVal(){
      return val;
   }
   public void setVal(float val){
      this.val = val; 
   }
   public void addVars(Set<Variable> vars){
      if(!this.constant) vars.add(this);
   }
   protected void updateDerivatives(){}
   public String toString(){
     if(name == null) return super.toString();
     return String.format("[%s, val=%f]", name, val);
   }
}

class Product extends Trans{
   Trans a, b;
  
   public Product(Trans a, Trans b) {
       super(new Trans[]{a, b});
       this.a = a;
       this.b = b;
   }
   protected float runCalcs() {
     return a.getResult() * b.getResult();
   }
   protected void updateDerivatives(){
     a.incDerivative(getDerivative() * b.getResult());
     b.incDerivative(getDerivative() * a.getResult());
   }
}

class Sum extends Trans {
  Trans[] last;
   public Sum(Trans[] last){
      super(last);
      this.last = last;
   }
   protected float runCalcs(){
      float sum = 0;
      for(Trans i : last) sum += i.getResult();
      return sum;
   }
   protected void updateDerivatives(){
     for(Trans i : last) i.incDerivative(this.getDerivative());
   }
}

class Exponent extends Trans {
    float by;
    Trans last;
  
    public Exponent(Trans last, float by){
        super(new Trans[]{last});
        this.by = by;
        this.last = last;
    }
    protected float runCalcs(){
       return (float) Math.pow(last.getResult(), by);
    }
    protected void updateDerivatives(){
      last.incDerivative(this.getDerivative() * by * (float) Math.pow(last.getResult(), by-1));
    }
}

class Sine extends Trans{
   Trans last;
  
   public Sine(Trans last){
      super(new Trans[]{last});
      this.last = last;
   }
   protected float runCalcs(){
     return (float) Math.sin(last.getResult());
   }
   protected void updateDerivatives(){
      last.incDerivative(this.getDerivative() * (float) Math.cos(last.getResult()));
   }
}

class Loss extends Trans {
   Trans last;
  
   public Loss(Trans last){
      super(new Trans[]{last});
      this.last = last;
   }
   
   protected float runCalcs(){
      return last.getResult();
   }
   
   protected void updateDerivatives(){
      last.incDerivative(1); 
   }
}

/**
* HOW TO USE THIS MODEL:
* Perform operations using Trans classes, let the roots be all variables & constants to run the model with -- this is required so that the model has all required information
* The Loss function is what everything is to the "derivative" of
* The outputs is just for safekeeping
* call runModel and everything will populate; update Variables using its derivative!
*/
class Model {
    Set<Variable> vars; // the parameters to optimize... 
    List<Variable> inputs;
    List<Trans> outputs;
    Trans loss;
    
    List<Trans> topoSort;
    
    public Model(List<Variable> roots, List<Trans> outputs, Loss loss) throws IllegalArgumentException{
      vars = new HashSet<Variable>();
      this.inputs = roots;
      this.loss = loss;
      
      topoSort = new ArrayList<>();
      for(Trans i : inputs) discoverGraph(i);
      Collections.reverse(topoSort);
    }
    
    Set<Trans> vis = new HashSet<>();
    private void discoverGraph(Trans cur){
      if(vis.contains(cur)) return;
      vis.add(cur);
      cur.addVars(this.vars);
      for(Trans i : cur.nextLayers()) discoverGraph(i);
      topoSort.add(cur);
    }
    
    // runs the calculations on the model but DOESN'T CHANGE anything
    public void runModel(){
      for(Trans i : topoSort) i.reset();
      for(Trans i : topoSort) i.forward();
      for(int i = topoSort.size() - 1; i >= 0; --i) topoSort.get(i).backward();
    } 
}

abstract class Optimizer{
   Variable[] vars;
   
   public Optimizer(Variable[] vars){
      this.vars = vars;
   }
   
   public abstract void optimize(); 
}

class Momentum extends Optimizer{
    float[] sqAvg;
    float rho;
    
    public Momentum(Variable[] vars, float rho){
       super(vars);
       this.rho = rho;
       this.sqAvg = new float[vars.length];
       for(int i = 0; i < vars.length; i++) sqAvg[i] = (float) 1;
    }
    
    /**
    * Optimize the variables based on their derivatives
    * impl note: make sure to call the model beforehand
    */
    public void optimize(){
      float[] divs = new float[vars.length];
      
      for(int i = 0; i < vars.length; i++) {
        divs[i] = vars[i].getDerivative();
        sqAvg[i] = rho * sqAvg[i] + (1-rho) * (float) Math.pow(Math.abs(divs[i]), 1);
      }
      
      System.out.println(divs[0]);
      
      for(int i = 0; i < vars.length; i++) {
         vars[i].setVal(vars[i].getVal() - divs[i] * (float) 0.01 / (sqAvg[i] + (float) 1));
      }
    }
}
