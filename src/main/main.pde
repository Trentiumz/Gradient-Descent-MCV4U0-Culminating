import java.util.*;
import java.util.stream.*;

void setup(){
  Variable a = new Variable(5, "a");
  Variable b = new Variable(5, "b");
  
  Input[] x = new Input[]{new Input(3), new Input(5)};
  Input[] y = new Input[]{new Input(0), new Input(6)};
  
  Trans[] ax = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) ax[i] = new Multiply(x[i], a);
  Trans[] plusB = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) plusB[i] = new Add(ax[i], b);
  Trans[] residual = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) residual[i] = new Add(plusB[i], new Variable(y[i].val * -1, true));
  Trans[] squaredResidual = new Trans[x.length];
  for(int i = 0; i < ax.length; i++) squaredResidual[i] = new Exponent(residual[i], 2);
  Trans totResidual = new Sum(squaredResidual);
  Loss loss = new Loss(totResidual);
  
  List<Input> allInputs = new ArrayList<Input>(Arrays.asList(x));
  for(Input i : y) allInputs.add(i);
  Model model = new Model(allInputs, Arrays.asList(plusB), loss);
  model.runModel();
  System.out.println(a.val + " " + a.derivative);
  System.out.println(b.val + " " + b.derivative);
}

void draw(){
  
}
