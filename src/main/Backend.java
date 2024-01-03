import java.util.*;

class Variable{
   public float val;
   public float derivative;
   public String name;
   public boolean constant=false;
   
   public Variable(float startVal, String name){
       this.val = startVal;
       this.derivative = 0;
       this.name = name;
   }
   public Variable(String name){
      this(0, name); 
   }
   public Variable(float startVal, boolean constant){
      this(startVal, null);
      this.constant = constant;
   }
}

/**
* A transformation takes in some number of inputs and returns one output
*/
abstract class Trans {
    private final Variable[] vars; // variables used
    
    private final Trans[] prev; // previous operations
    private final float[] lossOverFunc; // basically if the output from [prev] increased by a little bit, how much would the loss increase by?
    private List<Trans> nex; // next operations
    
    private float result; // result from a forward run
    
    private boolean forwardRun = false; // debugging, just to make sure everything's working properly ;)
    private boolean backwardRun = false;
    
    protected Trans(Trans[] prev, Variable[] vars){
      this.prev = prev;
      this.lossOverFunc = new float[prev.length];
      for(Trans i : prev){
        i.nex.add(this);
      }
      this.nex = new ArrayList<>();
      
      this.vars = vars;
      this.result = 0;
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
    
    // call updateDerivative() of nex first, now the variables in vars is updated with the derivatives from this layer & lossOverFunc is updated
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
    protected float lossOverTrans(Trans transFor) {
      return lossOverFunc[Arrays.asList(prev).indexOf(transFor)];
    }
    public float getResult() throws IllegalStateException{
      if(!forwardRun) throw new IllegalStateException("There isn't a result yet...");
       return result; 
    }
    public List<Trans> nextLayers(){
      return nex;
    }
    
    // set methods
    protected void setLossOverTrans(Trans transFor, float to){
       lossOverFunc[Arrays.asList(prev).indexOf(transFor)] = to; 
    }
    public void reset(){
       this.forwardRun = false;
       this.backwardRun = false;
    }
    public void addVars(Set<Variable> vars){
       for(Variable i : this.vars) if(!i.constant) vars.add(i);  
    }
}

class Multiply extends Trans{
   Trans last;
   Variable by;
  
   public Multiply(Trans last, Variable by) {
       super(new Trans[]{last}, new Variable[]{by});
       this.last = last;
       this.by = by;
   }
   protected float runCalcs() {
     return last.getResult() * by.val;
   }
   protected void updateDerivatives(){
     float toInput = 0;
     for(Trans i : nextLayers()) {
       by.derivative += i.lossOverTrans(this) * last.getResult();
       toInput += i.lossOverTrans(this) * by.val;
     }
     setLossOverTrans(last, toInput);
   }
}

class Add extends Trans{
   Trans last;
   Variable by;
  
   public Add(Trans last, Variable by) {
       super(new Trans[]{last}, new Variable[]{by});
       this.last = last;
       this.by = by;
   }
   
   protected float runCalcs(){
      return last.getResult() + by.val; 
   }
   
   protected void updateDerivatives(){
     float toInput = 0;
     for(Trans i : nextLayers()) {
       by.derivative += i.lossOverTrans(this);
       toInput += i.lossOverTrans(this);
     }
     setLossOverTrans(last, toInput);
   }
}

class Sum extends Trans {
  Trans[] last;
   public Sum(Trans[] last){
      super(last, new Variable[]{});
      this.last = last;
   }
   protected float runCalcs(){
      float sum = 0;
      for(Trans i : last) sum += i.getResult();
      return sum;
   }
   protected void updateDerivatives(){
      float toInput = 0;
      for(Trans i : nextLayers()){
         toInput += i.lossOverTrans(this);
      }
      for(Trans i : last) {
         setLossOverTrans(i, toInput); 
      }
   }
}

class Exponent extends Trans {
    float by;
    Trans last;
  
    public Exponent(Trans last, float by){
        super(new Trans[]{last}, new Variable[]{});
        this.by = by;
        this.last = last;
    }
    protected float runCalcs(){
       return (float) Math.pow(last.getResult(), by);
    }
    protected void updateDerivatives(){
      float toInput = 0;
      for(Trans i : nextLayers()){
         toInput += i.lossOverTrans(this) * by * (float) Math.pow(last.getResult(), by-1);
      }
      setLossOverTrans(last, toInput);
    }
}

class Loss extends Trans {
   Trans last;
  
   public Loss(Trans last){
      super(new Trans[]{last}, new Variable[]{});
      this.last = last;
   }
   
   protected float runCalcs(){
      return last.getResult();
   }
   
   protected void updateDerivatives(){
      setLossOverTrans(last, 1); 
   }
}

class Input extends Trans {
   public float val;
   public Input(float val){
      super(new Trans[]{}, new Variable[]{});
      this.val = val;
   }
   protected float runCalcs(){
      return val;
   }
   protected void updateDerivatives(){}
}

class Model {
    Set<Variable> vars; // the parameters to optimize... 
    List<Input> inputs;
    List<Trans> outputs;
    Trans loss;
    
    List<Trans> topoSort;
    
    public Model(List<Input> inputs, List<Trans> outputs, Loss loss) throws IllegalArgumentException{
      vars = new HashSet<Variable>();
      this.inputs = inputs;
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
      for(Variable i : vars) i.derivative = 0;
      System.out.println(topoSort);
      for(Trans i : topoSort) i.reset();
      for(Trans i : topoSort) i.forward();
      for(int i = topoSort.size() - 1; i >= 0; --i) topoSort.get(i).backward();
    }
}
